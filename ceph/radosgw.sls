{%- from "ceph/map.jinja" import radosgw with context %}
{%- if radosgw.enabled %}

include:
- ceph.client

ceph_radosgw_packages:
  pkg.installed:
  - names: {{ radosgw.pkgs }}

/var/lib/ceph/radosgw/ceph-radosgw.gateway/done:
  file.directory:
  - require:
    - pkg: ceph_radosgw_packages

radosgw_service:
  service.running:
  - name: {{ radosgw.services }}
  - enable: True
  - require:
    - pkg: ceph_radosgw_packages
    - file: /var/lib/ceph/radosgw/ceph-radosgw.gateway/done
  - watch:
    - file: /etc/ceph/ceph.conf

{%- endif %}