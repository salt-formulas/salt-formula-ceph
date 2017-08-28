{%- from "ceph/map.jinja" import common, setup with context %}
{%- if setup.enabled %}

include:
- ceph.common
{%- if setup.get('crush') %}
- ceph.setup.crush
{%- endif %}
{%- if setup.get('pool') %}
- ceph.setup.pool
{%- endif %}
{%- if common.get('keyring') %}
- ceph.setup.keyring
{%- endif %}

{%- endif %}
