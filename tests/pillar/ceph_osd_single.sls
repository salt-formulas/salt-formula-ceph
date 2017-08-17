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
    copy_admin_key: true
    journal_type: raw
    dmcrypt: disable
    osd_scenario: raw_journal_devices
    fs_type: xfs
    disk:
      '00':
        rule: hdd
        dev: /dev/vdb2
        journal: /dev/vdb1
        class: besthdd
        weight: 1.5
      '01':
        rule: hdd
        dev: /dev/vdc2
        journal: /dev/vdc1
        class: besthdd
        weight: 1.5
      '02':
        rule: hdd
        dev: /dev/vdd2
        journal: /dev/vdd1
        class: besthdd
        weight: 1.5
