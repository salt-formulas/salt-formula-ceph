{%- from "ceph/map.jinja" import osd with context %}

{% set ceph_version = pillar.ceph.common.version %}

{%- for backend_name, backend in osd.backend.iteritems() %}

{%- for disk in backend.disks %}

{%- if disk.get('enabled', True) %}

{% set dev = disk.dev %}

{%- for disk_id, ceph_disk in salt['grains.get']('ceph:ceph_disk', {}).iteritems() %}

{%- if ceph_disk.get('dev') == dev %}

{%- if ceph_version not in ['kraken', 'jewel'] %}

{%- if disk.class is defined %}

update_class_disk_{{ dev }}:
  cmd.run:
  - name: "ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd crush rm-device-class osd.{{ disk_id }}; ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd crush set-device-class {{ disk.class }} osd.{{ disk_id }}"
  - unless: "ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd tree | awk '{print $2,$4}' | grep -w osd.{{ disk_id }} | grep {{ disk.class }}"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- endif %}

{%- if disk.weight is defined %}

update_weight_disk_{{ dev }}:
  cmd.run:
  - name: "ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd crush reweight osd.{{ disk_id }} {{ disk.weight }}"
  - unless: "ceph -c /etc/ceph/{{ common.get('cluster_name', 'ceph') }}.conf osd tree | awk '{print $2,$3,$4}' | grep -w osd.{{ disk_id }} | grep {{ disk.weight }}"
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}

{%- endif %}

{%- endfor %}

{%- endif %}

{%- endfor %}

{%- endfor %}
