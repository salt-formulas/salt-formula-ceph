{%- from "ceph/map.jinja" import common with context %}

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

{%- if keyring.name is defined %}

{%- if keyring.name != 'admin' and keyring.key is defined and common.get("manage_keyring", False) %}

/etc/ceph/ceph.client.{{ keyring.name }}.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - defaults:
      keyring: {{ keyring|yaml }}
      name: {{ keyring.name }}

ceph_import_keyring_{{ keyring.name }}:
  cmd.run:
  - name: "ceph auth import -i /etc/ceph/ceph.client.{{ keyring.name }}.keyring"
  - onchanges:
    - file: /etc/ceph/ceph.client.{{ keyring.name }}.keyring

{%- elif keyring.name != 'admin' %}

ceph_create_keyring_{{ keyring.name }}:
  cmd.run:
  - name: "ceph auth get-or-create client.{{ keyring.name }} {%- for cap_name, cap in  keyring.caps.iteritems() %} {{ cap_name }} '{{ cap }}' {%- endfor %} > /etc/ceph/ceph.client.{{ keyring.name }}.keyring"
  - unless: "test -f /etc/ceph/ceph.client.{{ keyring.name }}.keyring"

{%- endif %}

{%- else %}

{%- if keyring_name != 'admin' and keyring.key is defined and common.get("manage_keyring", False) %}

/etc/ceph/ceph.client.{{ keyring_name }}.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - defaults:
      keyring: {{ keyring|yaml }}
      name: {{ keyring_name }}

ceph_import_keyring_{{ keyring_name }}:
  cmd.run:
  - name: "ceph auth import -i /etc/ceph/ceph.client.{{ keyring_name }}.keyring"
  - onchanges:
    - file: /etc/ceph/ceph.client.{{ keyring_name }}.keyring

{%- elif keyring_name != 'admin' %}

ceph_create_keyring_{{ keyring_name }}:
  cmd.run:
  - name: "ceph auth get-or-create client.{{ keyring_name }} {%- for cap_name, cap in  keyring.caps.iteritems() %} {{ cap_name }} '{{ cap }}' {%- endfor %} > /etc/ceph/ceph.client.{{ keyring_name }}.keyring"
  - unless: "test -f /etc/ceph/ceph.client.{{ keyring_name }}.keyring"

{%- endif %}

{%- endif %}

{% endfor %}
