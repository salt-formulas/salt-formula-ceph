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

{%- for node_name, node_grains in salt['mine.get']('ceph:common:keyring:admin', 'grains.items', 'pillar').iteritems() %}

{%- if node_grains.ceph is defined and node_grains.ceph.ceph_keyring is defined and node_grains.ceph.ceph_keyring.admin is defined %}

{%- if loop.index0 == 0 %}

/etc/ceph/ceph.client.admin.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - unless: "test -f /etc/ceph/ceph.client.admin.keyring"
  - defaults:
      node_grains: {{ node_grains|yaml }}
  - require:
    - pkg: common_packages
    - file: common_config

{%- endif %}

{%- endif %}

{%- endfor %}


