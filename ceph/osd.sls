{%- from "ceph/map.jinja" import osd, common with context %}

include:
- ceph.common

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

prepare_disk_{{ dev }}:
  cmd.run:
  {%- if backend_name == 'bluestore' and disk.block_db is defined and disk.block_wal is defined %}
  - name: "ceph-disk prepare --bluestore {{ dev }} --block.db {{ disk.block_db }} --block.wal {{ disk.block_wal }}"
  {%- elif backend_name == 'bluestore' and disk.block_db is defined %}
  - name: "ceph-disk prepare --bluestore {{ dev }} --block.db {{ disk.block_db }}"
  {%- elif backend_name == 'bluestore' and disk.block_wal is defined %}
  - name: "ceph-disk prepare --bluestore {{ dev }} --block.wal {{ disk.block_wal }}"
  {%- elif backend_name == 'bluestore' %}
  - name: "ceph-disk prepare --bluestore {{ dev }}"
  {%- elif backend_name == 'filestore' and disk.journal is defined and ceph_version == 'luminous' %}
  - name: "ceph-disk prepare --filestore {{ dev }} {{ disk.journal }}"
  {%- elif backend_name == 'filestore' and ceph_version == 'luminous' %}
  - name: "ceph-disk prepare --filestore {{ dev }}"
  {%- elif backend_name == 'filestore' and disk.journal is defined and ceph_version != 'luminous' %}
  - name: "ceph-disk prepare {{ dev }} {{ disk.journal }}"
  {%- else %}
  - name: "ceph-disk prepare {{ dev }}"
  {%- endif %}
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
  - unless: "ceph-disk list | grep {{ dev }} | grep active"
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
  - name: "ceph-disk activate --activate-key /etc/ceph/ceph.client.bootstrap-osd.keyring {{ dev }}1"
  - unless: "ceph-disk list | grep {{ dev }} | grep active"
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

