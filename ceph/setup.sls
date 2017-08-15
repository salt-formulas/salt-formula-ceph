{%- from "ceph/map.jinja" import osd, common with context %}

/etc/ceph/crushmap:
  file.managed:
  - source: salt://ceph/files/crushmap
  - template: jinja
