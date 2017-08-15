{%- from "ceph/map.jinja" import setup with context %}
{%- if setup.enabled %}

/etc/ceph/crushmap:
  file.managed:
  - source: salt://ceph/files/crushmap
  - template: jinja

{%- for pool_name, pool in setup.pool.iteritems() %}

ceph_pool_{{ pool_name }}:
  cmd.run:
  - name: ceph osd pool create {{ pool_name }} {{ pool.pg_num }} {{ pool.type }}
  - unless: ceph osd lspools | grep {{ pool_name }}

{%- endfor %}

{%- endif %}
