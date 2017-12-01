applications:
- ceph
parameters:
  ceph:
    backup:
      server:
        enabled: true
        hours_before_full: 24
        full_backups_to_keep: 5
        key:
          ceph_pub_key:
            enabled: true
            key: ssh_rsa
