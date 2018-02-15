{%- from "ceph/map.jinja" import setup, common with context %}

/etc/ceph/crushmap:
  file.managed:
  - source: salt://ceph/files/crushmap
  - template: jinja

{%- if setup.crush.get('enforce', False) %}

ceph_compile_crush_map:
  cmd.run:
  - name: crushtool -c /etc/ceph/crushmap -o /etc/ceph/crushmap.compiled
  - onchanges:
    - file: /etc/ceph/crushmap

ceph_enforce_crush_map:
  cmd.run:
  - name: ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd setcrushmap -i /etc/ceph/crushmap.compiled
  - unless: "test -f /etc/ceph/crushmap.enforced"
  - require:
    - cmd: ceph_compile_crush_map

/etc/ceph/crushmap.enforced:
  file.managed:
  - content: { }
  - unless: "test -f /etc/ceph/crushmap.enforced"
  - require:
    - cmd: ceph_enforce_crush_map

{% set ceph_version = pillar.ceph.common.version %}

{# after crush map is setup set crush rule for a pool #}

{%- if setup.pool is defined %}

{%- for pool_name, pool in setup.pool.iteritems() %}

{%- for option_name, option_value in pool.iteritems() %}

{%- if option_name in ['crush_rule'] %}

{%- if ceph_version in ['kraken', 'jewel'] %}

ceph_pool_option_{{ pool_name }}_crush_ruleset:
  cmd.run:
  - name: ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd pool set {{ pool_name }} crush_ruleset {{ option_value }}
  - unless: "ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd pool get {{ pool_name }} crush_ruleset | grep 'crush_ruleset: {{ option_value }}'"

{%- else %}

ceph_pool_option_{{ pool_name }}_{{ option_name }}:
  cmd.run:
  - name: ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd pool set {{ pool_name }} {{ option_name }} {{ option_value }}
  - unless: "ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd pool get {{ pool_name }} {{ option_name }} | grep '{{ option_name }}: {{ option_value }}'"

{%- endif %}

{%- endif %}

{%- endfor %}

{%- endfor %}

{%- endif %}

{%- endif %}
