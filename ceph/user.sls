{%- if not salt['user.info']('ceph') %}
ceph_user:
  user.present:
    - name: ceph
    - home: /var/lib/ceph
    - uid: 304
    - gid: 304
    - shell: /bin/false
    - system: True
    - require_in:
      {%- if pillar.ceph.get('monitoring', {}).get('enabled', False) %}
      - pkg: ceph_monitoring_packages
      {%- endif %}
      {%- if pillar.ceph.get('osd', {}).get('enabled', False) %}
      - pkg: ceph_osd_packages
      {%- endif %}
      {%- if pillar.ceph.get('radosgw', {}).get('enabled', False) %}
      - pkg: ceph_radosgw_packages
      {%- endif %}

ceph_group:
  group.present:
    - name: ceph
    - gid: 304
    - system: True
    - require_in:
      - user: ceph_user
{%- endif %}

