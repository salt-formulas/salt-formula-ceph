{%- from "ceph/map.jinja" import client with context %}
{%- if client.enabled %}

ceph_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}

/etc/ceph:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

{%- for keyring_name, keyring in client.keyring.iteritems() %}

/etc/ceph/ceph.client.{{ keyring_name }}.keyring:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - replace: False
    # bug, if file is empty no section is added by options_present
    - contents: |
        [client.{{ keyring_name  }}]
    - require:
      - file: /etc/ceph

  ini.options_present:
  - sections:
      client.{{ keyring_name }}: {{ keyring|yaml }}
  - require:
    - pkg: ceph_client_packages

{%- endfor %}

{%- set config = client.config %}
{%- for keyring_name, keyring in client.keyring.iteritems() %}
{%- load_yaml as config_fragment %}
client.{{ keyring_name }}:
  keyring: /etc/ceph/ceph.client.{{ keyring_name }}.keyring
{%- endload %}
{%- set _dummy = config.update(config_fragment) %}
{%- endfor %}

/etc/ceph/ceph.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - replace: False
    # bug, if file is empty no section is added by options_present
    - contents: |
        [global]
    - require:
      - file: /etc/ceph

  ini.options_present:
  - sections: {{ config|yaml }}
  - require:
    - pkg: ceph_client_packages
    - file: /etc/ceph

{%- endif %}
