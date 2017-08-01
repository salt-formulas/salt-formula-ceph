{%- from "cpeh/map.jinja" import osd with context %}

include:
- ceph.user

osd_packages:
  pkg.installed:
  - names: {{ osd.pkgs }}

/etc/ceph/ceph.conf:
  file.managed:
  - source: salt://ceph/files/{{ ceph.version }}/ceph-osd.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: osd_packages

osd_services:
  service.running:
  - enable: true
  - names: {{ osd.services }}
  - watch:
    - file: /etc/ceph/ceph.conf
