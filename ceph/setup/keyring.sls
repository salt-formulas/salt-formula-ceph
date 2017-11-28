{%- from "ceph/map.jinja" import common with context %}

{% if not common.get('container_mode', False) %}

{# run only if ceph cluster is present #}
{%- for node_name, node_grains in salt['mine.get']('ceph:common:keyring:admin', 'grains.items', 'pillar').iteritems() %}

{%- if node_grains.ceph is defined and node_grains.ceph.ceph_keyring is defined and node_grains.ceph.ceph_keyring.admin is defined %}

{%- if loop.index0 == 0 %}

{% for keyring_name, keyring in common.get('keyring', {}).iteritems() %}

{%- if keyring.name is defined %}

{%- if keyring.name != 'admin' and keyring.key is defined and common.get("manage_keyring", False) %}

{{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring.name }}.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - defaults:
      keyring: {{ keyring|yaml }}
      name: {{ keyring.name }}

ceph_import_keyring_{{ keyring.name }}:
  cmd.run:
  - name: "ceph auth import -i {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring.name }}.keyring"
  - onchanges:
    - file: {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring.name }}.keyring

{%- elif keyring.name != 'admin' %}

ceph_create_keyring_{{ keyring.name }}:
  cmd.run:
  - name: "ceph auth get-or-create client.{{ keyring.name }} {%- for cap_name, cap in  keyring.caps.iteritems() %} {{ cap_name }} '{{ cap }}' {%- endfor %} > {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring.name }}.keyring"
  - unless: "test -f {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring.name }}.keyring"

{%- endif %}

{%- else %}

{%- if keyring_name != 'admin' and keyring.key is defined and common.get("manage_keyring", False) %}

{{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring_name }}.keyring:
  file.managed:
  - source: salt://ceph/files/keyring
  - template: jinja
  - defaults:
      keyring: {{ keyring|yaml }}
      name: {{ keyring_name }}

ceph_import_keyring_{{ keyring_name }}:
  cmd.run:
  - name: "ceph auth import -i {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring_name }}.keyring"
  - onchanges:
    - file: {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring_name }}.keyring

{%- elif keyring_name != 'admin' %}

ceph_create_keyring_{{ keyring_name }}:
  cmd.run:
  - name: "ceph auth get-or-create client.{{ keyring_name }} {%- for cap_name, cap in  keyring.caps.iteritems() %} {{ cap_name }} '{{ cap }}' {%- endfor %} > {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring_name }}.keyring"
  - unless: "test -f {{ common.prefix_dir }}/etc/ceph/ceph.client.{{ keyring_name }}.keyring"

{%- endif %}

{%- endif %}

{% endfor %}

{%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}
