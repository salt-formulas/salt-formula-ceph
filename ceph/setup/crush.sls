{%- from "ceph/map.jinja" import setup with context %}

/etc/ceph/crushmap:
  file.managed:
  - source: salt://ceph/files/crushmap
  - template: jinja

{%- if setup.crush.get('enforce', False) %}

ceph_compile_crush_map:
  cmd.run:
  - name: crushtool -c /etc/ceph/crushmap -o /etc/ceph/crushmap.compiled
  - unless: "test -f /etc/ceph/crushmap.compiled"

ceph_enforce_crush_map:
  cmd.run:
  - name: ceph osd setcrushmap -i /etc/ceph/crushmap.compiled; touch /etc/ceph/crushmap.enforced
  - unless: "test -f /etc/ceph/crushmap.enforced"

{# after crush map is setup enable appplication and crush rule for a pool #}

{%- if setup.pool is defined %}

{%- for pool_name, pool in setup.pool.iteritems() %}

{%- for option_name, option_value in pool.iteritems() %}

{%- if option_name in ['application', 'crush_rule'] %}

{%- if option_name == 'application' %}

ceph_pool_{{ pool_name }}_enable_{{ option_name }}:
  cmd.run:
  - name: ceph osd pool {{ option_name }} enable {{ pool_name }} {{ option_value }}
  - unless: "ceph osd pool {{ option_name }} get {{ pool_name }} | grep '{{ option_value }}'"

{%- else %}

ceph_pool_option_{{ pool_name }}_{{ option_name }}:
  cmd.run:
  - name: ceph osd pool set {{ pool_name }} {{ option_name }} {{ option_value }}
  - unless: "ceph osd pool get {{ pool_name }} {{ option_name }} | grep '{{ option_name }}: {{ option_value }}'"

{%- endif %}

{%- endif %}

{%- endfor %}

{%- endfor %}

{%- endif %}

{%- endif %}
