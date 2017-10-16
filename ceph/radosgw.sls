{%- from "ceph/map.jinja" import radosgw, common with context %}
{%- if radosgw.enabled %}

include:
- ceph.common
- ceph.setup.keyring

ceph_radosgw_packages:
  pkg.installed:
  - names: {{ radosgw.pkgs }}

radosgw_config:
  file.managed:
  - name: /etc/ceph/ceph.conf
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: ceph_radosgw_packages

/var/lib/ceph/radosgw/ceph-radosgw.gateway/done:
  file.touch:
  - makedirs: true
  - unless: "test -f /var/lib/ceph/radosgw/ceph-radosgw.gateway/done"
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
