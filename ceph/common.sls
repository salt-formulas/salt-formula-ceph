{%- from "ceph/map.jinja" import common with context %}

common_packages:
  pkg.installed:
  - names: {{ common.pkgs }}

common_config:
  file.managed:
  - name: /etc/ceph/ceph.conf
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: common_packages

{%- if common.keyring is defined and common.keyring.admin is defined %}

ceph_create_keyring_admin:
  cmd.run:
  - name: "ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin {%- for cap_name, cap in  common.keyring.admin.caps.iteritems() %} --cap {{ cap_name }} '{{ cap }}' {%- endfor %}"
  - unless: "test -f /etc/ceph/ceph.client.admin.keyring"
  - require:
    - pkg: common_packages
    - file: common_config

{%- endif %}

/etc/ceph/ceph.client.admin.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - unless: "test -f /etc/ceph/ceph.client.admin.keyring"
  - require:
    - pkg: common_packages
    - file: common_config
