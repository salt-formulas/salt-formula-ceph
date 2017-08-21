{%- from "ceph/map.jinja" import setup with context %}

/etc/ceph/crushmap:
  file.managed:
  - source: salt://ceph/files/crushmap
  - template: jinja
