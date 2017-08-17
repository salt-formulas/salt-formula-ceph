{%- from "ceph/map.jinja" import radosgw with context %}
{%- if radosgw.enabled %}

include:
- ceph.common

ceph_radosgw_packages:
  pkg.installed:
  - names: {{ radosgw.pkgs }}

/var/lib/ceph/radosgw/ceph-radosgw.gateway/done:
  file.touch:
  - makedirs: true
  - require:
    - pkg: ceph_radosgw_packages

radosgw_service:
  service.running:
  - names: {{ radosgw.services }}
  - enable: True
  - require:
    - pkg: ceph_radosgw_packages
    - file: /var/lib/ceph/radosgw/ceph-radosgw.gateway/done
  - watch:
    - file: /etc/ceph/ceph.conf
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}
