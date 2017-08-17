{%- from "ceph/map.jinja" import client with context %}
{%- if client.enabled %}

{% if not client.container_mode %}

ceph_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

{%- endif %}

{{ client.prefix_dir }}/etc/ceph:
  file.directory:
  - user: root
  - group: root
  - mode: 755
  - makedirs: True

{%- for keyring_name, keyring in client.keyring.iteritems() %}

{{ client.prefix_dir }}/etc/ceph/ceph.client.{{ keyring_name }}.keyring:
  file.managed:
  - user: root
  - group: root
  - mode: 644
  - replace: False
  # bug, if file is empty no section is added by options_present
  - contents: |
      [client.{{ keyring_name  }}]
  - require:
    - file: {{ client.prefix_dir }}/etc/ceph
  ini.options_present:
  - sections:
      client.{{ keyring_name }}: {{ keyring|yaml }}
  {% if not client.container_mode %}
  - require:
    - pkg: ceph_client_packages
  {%- endif %}

{%- endfor %}

{%- set config = client.config %}
{%- for keyring_name, keyring in client.keyring.iteritems() %}
{%- load_yaml as config_fragment %}
client.{{ keyring_name }}:
  keyring: /etc/ceph/ceph.client.{{ keyring_name }}.keyring
{%- endload %}
{%- do config.update(config_fragment) %}
{%- endfor %}

{{ client.prefix_dir }}/etc/ceph/ceph.conf:
  file.managed:
  - user: root
  - group: root
  - mode: 644
  - replace: False
  # bug, if file is empty no section is added by options_present
  - contents: |
      [global]
  - require:
    - file: {{ client.prefix_dir }}/etc/ceph
  ini.options_present:
  - sections: {{ config|yaml }}
  - require:
    {% if not client.container_mode %}
    - pkg: ceph_client_packages
    {%- endif %}
    - file: {{ client.prefix_dir }}/etc/ceph

{%- endif %}