{%- from "ceph/map.jinja" import common, mon with context %}

include:
- ceph.common

mon_packages:
  pkg.installed:
  - names: {{ mon.pkgs }}

/etc/ceph/ceph.conf:
  file.managed:
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: mon_packages

cluster_secret_key:
  cmd.run:
  - name: "ceph-authtool --create-keyring /etc/ceph/ceph.mon.{{ grains.nodename }}.keyring --gen-key -n mon. --cap mon 'allow *'"
  - unless: "test -f /etc/ceph/ceph.mon.{{ grains.nodename }}.keyring"

add_admin_keyring_to_mon_keyring:
  cmd.run:
  - name: "ceph-authtool /etc/ceph/ceph.mon.{{ grains.nodename }}.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring"
  - unless: "test -f /var/lib/ceph/mon/ceph-{{ grains.nodename }}/done"

generate_monmap:
  cmd.run:
  - name: "monmaptool --create {%- for member in common.members %} --add {{ member.name }} {{ member.host }} {%- endfor %} --fsid {{ common.fsid }} /tmp/monmap"
  - unless: "test -f /tmp/monmap"


#/var/lib/ceph/mon/ceph-{{ grains.nodename }}:
#  file.directory:
#    - user: ceph
#    - group: ceph
#    - mode: 655
#    - makedirs: True

/etc/ceph/ceph.mon.{{ grains.nodename }}.keyring:
  file.managed:
  - user: ceph
  - group: ceph
  - replace: false
  

populate_monmap:
  cmd.run:
  - name: "sudo -u ceph ceph-mon --mkfs -i {{ grains.nodename }} --monmap /tmp/monmap"
  - unless: "test -f /var/lib/ceph/mon/ceph-{{ grains.nodename }}/kv_backend"

/var/lib/ceph/mon/ceph-{{ grains.nodename }}/keyring:
  file.managed:
  - source: salt://ceph/files/mon_keyring
  - template: jinja

/var/lib/ceph/mon/ceph-{{ grains.nodename }}/done:
  file.managed:
    - user: ceph
    - group: ceph
    - content: { }

mon_services:
  service.running:
  - enable: true
  - names: [ceph-mon@{{ grains.nodename }}]
  - watch:
    - file: /etc/ceph/ceph.conf
  - require:
    - pkg: mon_packages
