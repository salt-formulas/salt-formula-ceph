ceph:
  client:
    enabled: true
    config:
      global:
        fsid: 00000000-0000-0000-0000-000000000000
        mon initial members: ceph1,ceph2,ceph3
        mon host: 10.103.255.252:6789,10.103.255.253:6789,10.103.255.254:6789
        osd_fs_mkfs_arguments_xfs:
        osd_fs_mount_options_xfs: rw,noatime
        network public: 10.0.0.0/24
        network cluster: 10.0.0.0/24
        osd_fs_type: xfs
      osd:
        osd journal size: 7500
        filestore xattr use omap: true
      mon:
        mon debug dump transactions: false
    keyring:
      cinder:
        key: 00000000000000000000000000000000000000==
      glance:
        key: 00000000000000000000000000000000000000==

