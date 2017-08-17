ceph:
  common:
    version: kraken
    config:
      global:
        param1: value1
        param2: value1
        param3: value1
      mon:
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
  mon:
    enabled: true
    version: kraken
    keyring:
      mon:
        key: AQAnQIhZ6in5KxAAdf467upoRMWFcVg5pbh1yg==
        caps:
          mon: "allow *"
      admin:
        key: AQBHPYhZv5mYDBAAvisaSzCTQkC5gywGUp/voA==
        caps:
          mds: "allow *"
          mgr: "allow *"
          mon: "allow *"
          osd: "allow *"
