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

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

{%- if keyring_name == 'admin' and keyring.key is undefined %}

ceph_create_keyring_{{ keyring_name }}:
  cmd.run:
  - name: "ceph-authtool --create-keyring /etc/ceph/ceph.client.{{ keyring_name }}.keyring --gen-key -n client.{{ keyring_name }} {%- for cap_name, cap in  keyring.caps.iteritems() %} --cap {{ cap_name }} '{{ cap }}' {%- endfor %}"
  - unless: "test -f /etc/ceph/ceph.client.{{ keyring_name }}.keyring"
  - require:
    - pkg: common_packages
    - file: common_config

{%- endif %}

{% endfor %}

/etc/ceph/ceph.client.admin.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - unless: "test -f /etc/ceph/ceph.client.admin.keyring"
  - require:
    - pkg: common_packages
    - file: common_config
