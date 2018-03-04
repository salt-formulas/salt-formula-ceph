{%- from "ceph/map.jinja" import backup with context -%}
#!/bin/bash

# Script to erase old backups on ceph 'server role' node.
# ---------

    BACKUPDIR="{{ backup.backup_dir }}/full"
    KEEP={{ backup.server.full_backups_to_keep }}
    {%- if backup.server.backup_times is not defined %}
    HOURSFULLBACKUPLIFE={{ backup.server.hours_before_full }} # Lifetime of the latest full backup in hours
    if [ $HOURSFULLBACKUPLIFE -gt 24 ]; then
        FULLBACKUPLIFE=$(( 24 * 60 * 60 ))
    else
        FULLBACKUPLIFE=$(( $HOURSFULLBACKUPLIFE * 60 * 60 ))
    fi
    {%- endif %}

# Cleanup
# ---------
{%- if backup.server.backup_times is not defined %}
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