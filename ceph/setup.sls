{%- from "ceph/map.jinja" import setup with context %}
{%- if setup.enabled %}

/etc/ceph/crushmap:
  file.managed:
  - source: salt://ceph/files/crushmap
  - template: jinja

{%- for pool_name, pool in setup.pool.iteritems() %}

ceph_pool_{{ pool_name }}:
  cmd.run:
  - name: ceph osd pool create {{ pool_name }} {{ pool.pg_num }}{% if pool.pgp_num is defined %} {{ pool.pgp_num }}{% endif %} {{ pool.type }}{% if pool.erasure_code_profile is defined %} {{ pool.erasure_code_profile }}{% endif %}{% if pool.crush_ruleset_name is defined %} {{ pool.crush_ruleset_name }}{% endif %}{% if pool.expected_num_objects is defined %} {{ pool.expected_num_objects }}{% endif %}
  - unless: ceph osd lspools | grep {{ pool_name }}

{%- endfor %}

{%- endif %}
