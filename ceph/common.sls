{%- from "ceph/map.jinja" import common with context %}

base_packages:
  pkg.installed:
  - names: {{ common.pkgs }}

base_config:
  file.managed:
  - name: /etc/ceph/ceph.conf
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: base_packages

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

/etc/ceph/ceph.client.{{ keyring_name }}.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - defaults:
      name: {{ keyring_name }}
      keyring: {{ keyring }}

{% endfor %}
