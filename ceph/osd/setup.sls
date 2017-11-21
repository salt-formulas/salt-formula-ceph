{%- from "ceph/map.jinja" import osd, common with context %}

ceph_osd_packages:
  pkg.installed:
  - names: {{ osd.pkgs }}

/etc/ceph/ceph.conf:
  file.managed:
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: ceph_osd_packages

{% set ceph_version = pillar.ceph.common.version %}

{%- for backend_name, backend in osd.backend.iteritems() %}

{%- for disk in backend.disks %}

{%- if disk.get('enabled', True) %}

{% set dev = disk.dev %}

zap_disk_{{ dev }}:
  cmd.run:
  - name: "ceph-disk zap {{ dev }}"
  - unless: "ceph-disk list | grep {{ dev }} | grep ceph"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- if disk.journal is defined %}

zap_disk_journal_{{ disk.journal }}_for_{{ dev }}:
  cmd.run:
  - name: "ceph-disk zap {{ disk.journal }}"
  - unless: "ceph-disk list | grep {{ disk.journal }} | grep ceph"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
    - cmd: zap_disk_{{ dev }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- if disk.block_db is defined %}

zap_disk_blockdb_{{ disk.block_db }}_for_{{ dev }}:
  cmd.run:
  - name: "ceph-disk zap {{ disk.block_db }}"
  - unless: "ceph-disk list | grep {{ disk.block_db }} | grep ceph"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
    - cmd: zap_disk_{{ dev }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- if disk.block_wal is defined %}

zap_disk_blockwal_{{ disk.block_wal }}_for_{{ dev }}:
  cmd.run:
  - name: "ceph-disk zap {{ disk.block_wal }}"
  - unless: "ceph-disk list | grep {{ disk.block_wal }} | grep ceph"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
    - cmd: zap_disk_{{ dev }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- set cmd = [] %}
{%- if disk.get('dmcrypt', False) %}
{%- do cmd.append('--dmcrypt') %}
{%- do cmd.append('--dmcrypt-key-dir ' + disk.get('dmcrypt_key_dir', '/etc/ceph/dmcrypt-keys')) %}
{%- endif %}
{%- do cmd.append('--prepare-key /etc/ceph/ceph.client.bootstrap-osd.keyring') %}
{%- if backend_name == 'bluestore' %}
{%- do cmd.append('--bluestore') %}
{%- if disk.block_db is defined %}
{%- do cmd.append('--block.db ' + disk.block_db) %}
{%- endif %}
{%- if disk.block_wal is defined %}
{%- do cmd.append('--block.wal ' + disk.block_wal) %}
{%- endif %}
{%- do cmd.append(dev) %}
{%- elif backend_name == 'filestore' and ceph_version not in ['kraken', 'jewel'] %}
{%- do cmd.append('--filestore') %}
{%- do cmd.append(dev) %}
{%- if disk.journal is defined %}
{%- do cmd.append(disk.journal) %}
{%- endif %}
{%- elif backend_name == 'filestore' %}
{%- do cmd.append(dev) %}
{%- if disk.journal is defined %}
{%- do cmd.append(disk.journal) %}
{%- endif %}
{%- endif %}

prepare_disk_{{ dev }}:
  cmd.run:
  - name: "yes | ceph-disk prepare {{ cmd|join(' ') }}"
  - unless: "ceph-disk list | grep {{ dev }} | grep ceph"
  - require:
    - cmd: zap_disk_{{ dev }}
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

reload_partition_table_{{ dev }}:
  cmd.run:
  - name: "partprobe"
  - unless: "lsblk -p | grep {{ dev }} -A1 | grep -v lockbox | grep ceph | grep osd"
  - require:
    - cmd: prepare_disk_{{ dev }}
    - cmd: zap_disk_{{ dev }}
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

activate_disk_{{ dev }}:
  cmd.run:
{%- if disk.get('dmcrypt', False) %}
  - name: "ceph-disk activate --dmcrypt --activate-key /etc/ceph/ceph.client.bootstrap-osd.keyring {{ dev }}1"
{%- else %}
  - name: "ceph-disk activate --activate-key /etc/ceph/ceph.client.bootstrap-osd.keyring {{ dev }}1"
{%- endif %}
  - unless: "lsblk -p | grep {{ dev }} -A1 | grep -v lockbox | grep ceph | grep osd"
  - require:
    - cmd: prepare_disk_{{ dev }}
    - cmd: zap_disk_{{ dev }}
    - pkg: ceph_osd_packages
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- endfor %}

{%- endfor %}

osd_services_global:
  service.running:
  - enable: true
  - names: ['ceph-osd.target']
  - watch:
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

osd_services:
  service.running:
  - enable: true
  - names: ['ceph.target']
  - watch:
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
