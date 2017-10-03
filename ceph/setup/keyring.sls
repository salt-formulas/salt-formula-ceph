{%- from "ceph/map.jinja" import common with context %}

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

{%- if keyring_name != 'admin' %}

ceph_create_keyring_{{ keyring_name }}:
  cmd.run:
  - name: "ceph auth get-or-create client.{{ keyring_name }} {%- for cap_name, cap in  keyring.caps.iteritems() %} {{ cap_name }} '{{ cap }}' {%- endfor %} > /etc/ceph/ceph.client.{{ keyring_name }}.keyring"
  - unless: "test -f /etc/ceph/ceph.client.{{ keyring_name }}.keyring"

{%- endif %}

{% endfor %}
