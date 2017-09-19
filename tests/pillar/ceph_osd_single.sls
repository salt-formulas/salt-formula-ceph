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
    version: kraken
    host_id: 10
    backend:
      filestore:
        disks:
        - dev: /dev/sdm
          enabled: false
          rule: hdd
          journal: /dev/sdn
          fs_type: xfs
          class: bestssd
          weight: 1.5
        - dev: /dev/sdl
          rule: hdd
          fs_type: xfs
          class: bestssd
          weight: 1.5
        - dev: /dev/sdo
          rule: hdd
          journal: /dev/sdo
          fs_type: xfs
          class: bestssd
          weight: 1.5
      bluestore:
        disks:
        - dev: /dev/sdb
          enabled: false
        - dev: /dev/sdc
