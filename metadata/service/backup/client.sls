applications:
- ceph
parameters:
  ceph:
    backup:
      client:
        enabled: true
        full_backups_to_keep: 3
        hours_before_full: 24
        # target:
        #   host: cfg01
