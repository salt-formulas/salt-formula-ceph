{%- from "ceph/map.jinja" import common with context %}

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

ceph_keyring_{{ keyring_name }}_import:
  cmd.run:
  - name: ceph auth import -i /etc/ceph/ceph.client.{{ keyring_name }}.keyring
  - unless: ceph auth list | grep {{ keyring_name }}

{%- endfor %}

{%- endif %}
