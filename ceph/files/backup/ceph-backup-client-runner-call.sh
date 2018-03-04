{%- from "ceph/map.jinja" import backup with context -%}
#!/bin/bash
# Script to call ceph-backup-runner.sh in for loop to backup all keyspaces.
# This script is also able to rsync backed up data to remote host and perform clean up on historical backups

SKIPCLEANUP=false
while getopts "sf" opt; do
  case $opt in
    s)
      echo "Cleanup will be skipped" >&2
      SKIPCLEANUP=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Configuration
# -------------
    BACKUPDIR="{{ backup.backup_dir }}/full"
    SERVERBACKUPDIR="{{ backup.client.target.get('backup_dir', backup.backup_dir) }}"
    TMPDIR="$( pwd )/tmp_ceph_backup"
    HOSTNAME="$( hostname )"
    TIMESTAMP="$( date +%m%d%k%M )"

    SCRIPTDIR="/usr/local/bin"
    KEEP={{ backup.client.full_backups_to_keep }}
    {%- if backup.client.backup_times is not defined %}
    HOURSFULLBACKUPLIFE={{ backup.client.hours_before_full }} # Lifetime of the latest full backup in hours
    if [ $HOURSFULLBACKUPLIFE -gt 24 ]; then
        FULLBACKUPLIFE=$(( 24 * 60 * 60 ))
    else
        FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
    fi
    {%- endif %}
    RSYNCLOGDIR="/var/log/backups"
    RSYNCLOG="/var/log/backups/ceph-rsync.log"

# Functions
# ---------
    function check_dependencies() {
        # Function to iterate through a list of required executables to ensure
        # they are installed and executable by the current user.
        DEPS="awk basename cp cqlsh date dirname echo find "
        DEPS+="getopt grep hostname mkdir rm sed tail tar "
        for bin in $DEPS; do
            $( which $bin >/dev/null 2>&1 ) || NOTFOUND+="$bin "
        done

        if [ ! -z "$NOTFOUND" ]; then
            printf "Error finding required executables: ${NOTFOUND}\n" >&2
            exit 1
        fi
    }


    # Need write access to local directory to create dump file
    if [ ! -w $( pwd ) ]; then
        printf "You must have write access to the current directory $( pwd )\n"
        exit 1
    fi

    if [ ! -d "$RSYNCLOGDIR" ] && [ ! -e "$RSYNCLOG" ]; then
        mkdir -p "$RSYNCLOGDIR"
    fi

    $SCRIPTDIR/ceph-backup-runner.sh

# rsync just the new or modified backup files
# ---------

    {%- if backup.client.target is defined %}
    echo "Adding ssh-key of remote host to known_hosts"
    ssh-keygen -R {{ backup.client.target.host }} 2>&1 | > $RSYNCLOG
    ssh-keyscan {{ backup.client.target.host }} >> ~/.ssh/known_hosts  2>&1 | >> $RSYNCLOG
    echo "Rsyncing files to remote host"
    /usr/bin/rsync -rhtPv --rsync-path=rsync --progress $BACKUPDIR/* -e ssh ceph@{{ backup.client.target.host }}:$SERVERBACKUPDIR >> $RSYNCLOG

    # Check if the rsync succeeded or failed
    if [ -s $RSYNCLOG ] && ! grep -q "rsync error: " $RSYNCLOG; then
            echo "Rsync to remote host completed OK"
    else
            echo "Rsync to remote host FAILED"
            exit 1
    fi
    {%- endif %}

# Cleanup
# ---------
if [ $SKIPCLEANUP = false ] ; then
    {%- if backup.client.backup_times is not defined %}
    echo "----------------------------"
    echo "Cleanup. Keeping only $KEEP full backups"
    AGE=$(($FULLBACKUPLIFE * $KEEP / 60))
    find $BACKUPDIR -maxdepth 1 -type d -mmin +$AGE -execdir echo "removing: "$BACKUPDIR/{} \; -execdir rm -rf $BACKUPDIR/{} \;
    {%- else %}
    echo "----------------------------"
    echo "Cleanup. Keeping only $KEEP full backups"
    NUMBER_OF_FULL=`find $BACKUPDIR -maxdepth 1 -mindepth 1 -type d -print| wc -l`
    FULL_TO_DELETE=$(( $NUMBER_OF_FULL - $KEEP ))
    if [ $FULL_TO_DELETE -gt 0 ] ; then
        cd $BACKUPDIR
        ls -t | tail -n -$FULL_TO_DELETE | xargs -d '\n' rm -rf
    else
        echo "There are less full backups than required, not deleting anything."
    fi
    {%- endif %}
else
    echo "----------------------------"
    echo "-s parameter passed. Cleanup was not triggered"
fi