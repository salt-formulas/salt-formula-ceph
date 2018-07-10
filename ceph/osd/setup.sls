{%- from "ceph/map.jinja" import osd, common with context %}

ceph_osd_packages:
  pkg.installed:
  - names: {{ osd.pkgs }}

/etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf:
  file.managed:
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: ceph_osd_packages

{% set ceph_version = pillar.ceph.common.version %}

{%- if osd.backend is defined %}

{%- for backend_name, backend in osd.backend.iteritems() %}

{%- for disk in backend.disks %}

{%- if disk.get('enabled', True) %}

{% set dev = disk.dev %}

# for uniqueness
{% set dev_device = dev + disk.get('data_partition', 1)|string %}

#{{ dev }}{{ disk.get('data_partition', 1) }}

zap_disk_{{ dev_device }}:
  cmd.run:
  - name: "ceph-disk zap {{ dev }}"
  - unless: "ceph-disk list | grep {{ dev }} | grep -e 'ceph' -e 'mounted'"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- if disk.journal is defined %}

zap_disk_journal_{{ disk.journal }}_for_{{ dev_device }}:
  cmd.run:
  - name: "ceph-disk zap {{ disk.journal }}"
  - unless: "ceph-disk list | grep {{ disk.journal }} | grep -e 'ceph' -e 'mounted'"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
    - cmd: zap_disk_{{ dev_device }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- if disk.block_db is defined %}

zap_disk_blockdb_{{ disk.block_db }}_for_{{ dev_device }}:
  cmd.run:
  - name: "ceph-disk zap {{ disk.block_db }}"
  - unless: "ceph-disk list | grep {{ disk.block_db }} | grep -e 'ceph' -e 'mounted'"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
    - cmd: zap_disk_{{ dev_device }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- if disk.block_wal is defined %}

zap_disk_blockwal_{{ disk.block_wal }}_for_{{ dev_device }}:
  cmd.run:
  - name: "ceph-disk zap {{ disk.block_wal }}"
  - unless: "ceph-disk list | grep {{ disk.block_wal }} | grep -e 'ceph' -e 'mounted'"
  - require:
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
    - cmd: zap_disk_{{ dev_device }}
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- set cmd = [] %}
{%- do cmd.append('--cluster ' + common.get('cluster_name', 'ceph')) %}
{%- do cmd.append('--cluster-uuid ' + common.fsid) %}
{%- if disk.get('dmcrypt', False) %}
  {%- do cmd.append('--dmcrypt') %}
  {%- do cmd.append('--dmcrypt-key-dir ' + disk.get('dmcrypt_key_dir', '/etc/ceph/dmcrypt-keys')) %}
{%- endif %}
{%- if disk.lockbox_partition is defined %}
  {%- do cmd.append('--lockbox-partition-number ' + disk.lockbox_partition|string) %}
{%- endif %}
{%- do cmd.append("--prepare-key /etc/ceph/" + common.get('cluster_name', 'ceph') + ".client.bootstrap-osd.keyring") %}
{%- if disk.data_partition is defined %}
  {%- do cmd.append('--data-partition-number ' + disk.data_partition|string) %}
{%- endif %}
{%- if disk.data_partition_size is defined %}
  {%- do cmd.append('--data-partition-size ' + disk.data_partition_size|string) %}
{%- endif %}
{%- if backend_name == 'bluestore' %}
  {%- do cmd.append('--bluestore') %}
  {%- if disk.block_partition is defined %}
    {%- do cmd.append('--block-partition-number ' + disk.block_partition|string) %}
  {%- endif %}
  {%- if disk.block_db is defined %}
    {%- if disk.block_db_dmcrypt is defined and not disk.block_db_dmcrypt %}
      {%- do cmd.append('--block-db-non-dmcrypt') %}
    {%- elif disk.get('block_db_dmcrypt', False) %}
      {%- do cmd.append('--block-db-dmcrypt') %}
    {%- endif %}
    {%- if disk.block_db_partition is defined %}
      {%- do cmd.append('--block-db-partition-number ' + disk.block_db_partition|string) %}
    {%- endif %}
  {%- do cmd.append('--block.db ' + disk.block_db) %}
  {%- endif %}
  {%- if disk.block_wal is defined %}
    {%- if disk.block_wal_dmcrypt is defined and not disk.block_wal_dmcrypt %}
      {%- do cmd.append('--block-wal-non-dmcrypt') %}
    {%- elif disk.get('block_wal_dmcrypt', False) %}
      {%- do cmd.append('--block-wal-dmcrypt') %}
    {%- endif %}
    {%- if disk.block_wal_partition is defined %}
      {%- do cmd.append('--block-wal-partition-number ' + disk.block_wal_partition|string) %}
    {%- endif %}
    {%- do cmd.append('--block.wal ' + disk.block_wal) %}
  {%- endif %}
  {%- do cmd.append(dev) %}
{%- elif backend_name == 'filestore' and ceph_version not in ['kraken', 'jewel'] %}
  {%- if disk.journal_dmcrypt is defined and not disk.journal_dmcrypt %}
    {%- do cmd.append('--journal-non-dmcrypt') %}
  {%- elif disk.get('journal_dmcrypt', False) %}
    {%- do cmd.append('--journal-dmcrypt') %}
  {%- endif %}
  {%- if disk.journal_partition is defined %}
    {%- do cmd.append('--journal-partition-number ' + disk.journal_partition|string) %}
  {%- endif %}
  {%- do cmd.append('--filestore') %}
  {%- do cmd.append(dev) %}
  {%- if disk.journal is defined %}
    {%- do cmd.append(disk.journal) %}
  {%- endif %}
{%- elif backend_name == 'filestore' %}
  {%- if disk.journal_dmcrypt is defined and not disk.journal_dmcrypt %}
    {%- do cmd.append('--journal-non-dmcrypt') %}
  {%- elif disk.get('journal_dmcrypt', False) %}
    {%- do cmd.append('--journal-dmcrypt') %}
  {%- endif %}
  {%- if disk.journal_partition is defined %}
    {%- do cmd.append('--journal-partition-number ' + disk.journal_partition|string) %}
  {%- endif %}
  {%- do cmd.append(dev) %}
  {%- if disk.journal is defined %}
    {%- do cmd.append(disk.journal) %}
  {%- endif %}
{%- endif %}

prepare_disk_{{ dev_device }}:
  cmd.run:
  - name: "yes | ceph-disk prepare {{ cmd|join(' ') }}"
  - unless: "ceph-disk list | grep {{ dev_device }} | grep -e 'ceph' -e 'mounted'"
  - require:
    - cmd: zap_disk_{{ dev_device }}
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

reload_partition_table_{{ dev_device }}:
  cmd.run:
  - name: "partprobe"
  - unless: "lsblk -p | grep {{ dev_device }} -A1 | grep -v lockbox | grep ceph | grep osd"
  - require:
    - cmd: prepare_disk_{{ dev_device }}
    - cmd: zap_disk_{{ dev_device }}
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- else %}
  - onlyif: ceph-disk list | grep {{ dev_device }} | grep ceph
  {%- endif %}

activate_disk_{{ dev_device }}:
  cmd.run:
{%- if disk.get('dmcrypt', False) %}
  - name: "ceph-disk activate --dmcrypt --activate-key /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.client.bootstrap-osd.keyring {{ dev_device }}"
{%- else %}
  - name: "ceph-disk activate --activate-key /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.client.bootstrap-osd.keyring {{ dev_device }}"
{%- endif %}
  - unless: "lsblk -p | grep {{ dev_device }} -A1 | grep -v lockbox | grep ceph | grep osd"
  - require:
    - cmd: prepare_disk_{{ dev_device }}
    - cmd: zap_disk_{{ dev_device }}
    - pkg: ceph_osd_packages
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- else %}
  - onlyif: ceph-disk list | grep {{ dev_device }} | grep ceph
  {%- endif %}

{%- endif %}

{%- endfor %}

{%- endfor %}

{%- endif %}

osd_services_global:
  service.running:
  - enable: true
  - names: ['ceph-osd.target']
  - watch:
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

osd_services:
  service.running:
  - enable: true
  - names: ['ceph.target']
  - watch:
    - file: /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}
