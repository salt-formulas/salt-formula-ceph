{%- from "ceph/map.jinja" import backup, mon, osd, common with context -%}
#!/bin/bash
# Script to backup ceph schema and create snapshot of keyspaces

# Configuration
# -------------
    BACKUPDIR="{{ backup.backup_dir }}/full"
    TMPDIR="$( pwd )/tmp_ceph_backup"
    HOSTNAME="$( hostname )"
    TIMESTAMP="$( date +%m%d%k%M )"

    # Need write access to local directory to create dump file
    if [ ! -w $( pwd ) ]; then
        printf "You must have write access to the current directory $( pwd )\n"
        exit 1
    fi

    # Create temporary working directory.  Yes, deliberately avoiding mktemp
    if [ ! -d "$TMPDIR" ] && [ ! -e "$TMPDIR" ]; then
        mkdir -p "$TMPDIR"
    else
        printf "Error creating temporary directory $TMPDIR"
        exit 1
    fi

    if [ ! -d "$TMPDIR/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME" ] && [ ! -e "$TMPDIR/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME" ]; then
        mkdir -p "$TMPDIR/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME"
    else
        printf "Error creating temporary directory $TMPDIR/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME"
        exit 1
    fi

    # Create backup directory.
    if [ ! -d "$BACKUPDIR" ] && [ ! -e "$BACKUPDIR" ]; then
        mkdir -p "$BACKUPDIR"
    fi

    # Create Backup
    # --------------------

    mkdir -p "$BACKUPDIR/$HOSTNAME/"

{%- if osd.get('enabled', False) %}
    cp -a /etc/ceph/ $TMPDIR/
    rsync -arv --exclude=osd/{{ common.get('cluster_name', 'ceph') }}-*/current /var/lib/ceph $TMPDIR/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME/
{%- elif mon.get('enabled', False) %}
    cp -a /etc/ceph/ $TMPDIR/
    service ceph-mon@$HOSTNAME stop
    cp -a /var/lib/ceph/ $TMPDIR/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME/
    service ceph-mon@$HOSTNAME start
{%- endif %}

    tar -cvzf $BACKUPDIR/$HOSTNAME/{{ common.get('cluster_name', 'ceph') }}-$HOSTNAME-$TIMESTAMP.tgz $TMPDIR
    RC=$?

    if [ $RC -gt 0 ]; then
        printf "Error generating tar archive.\n"
        [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
        exit 1
    else
        printf "Successfully created backup\n"
        [ "$TMPDIR" != "/" ] && rm -rf "$TMPDIR"
        exit 0
    fi

# Fin.
