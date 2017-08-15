{%- from "ceph/map.jinja" import common with context %}

include:
- ceph.user

base_packages:
  pkg.installed:
  - names: {{ common.pkgs }}

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

/etc/ceph/ceph.client.{{ keyring_name  }}.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - defaults:
      name: {{ keyring_name }}
      keyring: {{ keyring }}

{% endfor %}
