{%- from "cpeh/map.jinja" import monitor with context %}

include:
- ceph.user

monitor_packages:
  pkg.installed:
  - names: {{ monitor.pkgs }}

/etc/ceph/ceph.conf:
  file.managed:
  - source: salt://ceph/files/{{ ceph.version }}/ceph-monitor.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: monitor_packages

monitor_services:
  service.running:
  - enable: true
  - names: {{ monitor.services }}
  - watch:
    - file: /etc/ceph/ceph.conf
