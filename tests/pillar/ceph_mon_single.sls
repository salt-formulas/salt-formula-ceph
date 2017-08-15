ceph:
  common:
    config:
      mon:
        key: value
  mon:
    enabled: true
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
