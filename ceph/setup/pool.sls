{%- from "ceph/map.jinja" import setup with context %}

{%- for pool_name, pool in setup.pool.iteritems() %}

ceph_pool_create_{{ pool_name }}:
  cmd.run:
  - name: ceph osd pool create {{ pool_name }} {{ pool.pg_num }}{% if pool.pgp_num is defined %} {{ pool.pgp_num }}{% endif %} {{ pool.type }}{% if pool.erasure_code_profile is defined %} {{ pool.erasure_code_profile }}{% endif %}{% if pool.crush_ruleset_name is defined %} {{ pool.crush_ruleset_name }}{% endif %}{% if pool.expected_num_objects is defined %} {{ pool.expected_num_objects }}{% endif %}
  - unless: "ceph osd pool ls | grep ^{{ pool_name }}"

{%- for option_name, option_value in pool.iteritems() %}

{%- if option_name != 'type' %}

ceph_pool_option_{{ pool_name }}_{{ option_name }}:
  cmd.run:
  - name: ceph osd pool set {{ pool_name }} {{ option_name }} {{ option_value }}
  - unless: "ceph osd pool get {{ pool_name }} {{ option_name }} | grep '{{ option_name }}: {{ option_value }}'"

{%- endif %}

{%- endfor %}

{%- endfor %}


