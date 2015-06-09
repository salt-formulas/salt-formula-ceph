{%- from "ceph/map.jinja" import client with context %}
{%- if client.enabled %}

ceph_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

{%- for keyring_name, keyring in client.keyring.iteritems() %}

/etc/ceph/ceph.client.{{ keyring_name }}.keyring:
  ini.options_present:
  - sections:
      client.{{ keyring_name }}: {{ keyring|yaml }}
  - require:
    - pkg: ceph_client_packages

{%- endfor %}

{#
{%- load_yaml as config %}
{{ client.config|yaml }}
{%- for keyring_name, keyring in client.keyring.iteritems() %}
client.{{ keyring_name }}:
  keyring: /etc/ceph/ceph.client.{{ keyring_name }}.keyring
{%- endfor %}
{%- endload %}
#}

{%- set config = client.config %}
{%- for keyring_name, keyring in client.keyring.iteritems() %}
{%- load_yaml as config_fragment %}
client.{{ keyring_name }}:
  keyring: /etc/ceph/ceph.client.{{ keyring_name }}.keyring
{%- endload %}
{%- set _dummy = config.update(config_fragment) %}
{%- endfor %}

/etc/ceph/ceph.conf:
  ini.options_present:
  - sections: {{ config|yaml }}
  - require:
    - pkg: ceph_client_packages

{%- endif %}