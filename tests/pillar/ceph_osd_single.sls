ceph:
  common:
    enabled: true
    version: kraken
    config:
      global:
        param1: value1
        param2: value1
        param3: value1
      osd:
        key: value
    fsid: a619c5fc-c4ed-4f22-9ed2-66cf2feca23d
    members:
    - name: cmn01
      host: 10.0.0.1
    - name: cmn02
      host: 10.0.0.2
    - name: cmn03
      host: 10.0.0.3
    keyring:
      admin:
        key: AQBHPYhZv5mYDBAAvisaSzCTQkC5gywGUp/voA==
        caps:
          mds: "allow *"
          mgr: "allow *"
          mon: "allow *"
          osd: "allow *"
  osd:
    enabled: true
    crush_parent: rack01
    version: kraken
    backend:
      filestore:
        disks:
        - dev: /dev/sdm
          enabled: false
          journal: /dev/sdn
          journal_dmcrypt: true
          class: bestssd
          weight: 1.5
        - dev: /dev/sdl
          class: bestssd
          weight: 1.5
          dmcrypt: true
        - dev: /dev/sdo
          journal: /dev/sdo
          journal_partition: 5
          data_partition: 9
          data_partition_size: 12000
          class: bestssd
          weight: 1.5
      bluestore:
        disks:
        - dev: /dev/sdb
          block_db: /dev/sdf
          block_wal: /dev/sdf
          enabled: true
          block_partition: 3
          block_db_partition: 3
          block_wal_partition: 4
          data_partition: 2
        - dev: /dev/sdc
          block_db: /dev/sdf
          block_wal: /dev/sdf
          dmcrypt: true
          block_db_dmcrypt: false
