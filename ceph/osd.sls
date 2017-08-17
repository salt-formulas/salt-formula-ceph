{%- from "ceph/map.jinja" import osd, common with context %}

include:
- ceph.common

ceph_osd_packages:
  pkg.installed:
  - names: {{ osd.pkgs }}

/etc/ceph/ceph.conf:
  file.managed:
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: ceph_osd_packages

{% for disk_id, disk in osd.disk.iteritems() %}

#Set ceph_host_id per node and interpolate
{% set id = osd.host_id~disk_id %} 

#Not needed - need to test
#create_osd_{{ id }}:
#  cmd.run:
#  - name: "ceph osd create $(ls -l /dev/disk/by-uuid | grep {{ disk.dev | replace("/dev/", "") }} | awk '{ print $9}') {{ id }} "

#Move this thing into linux
makefs_{{ id }}:
  module.run:
  - name: xfs.mkfs 
  - device: {{ disk.dev }}
  - unless: "ceph-disk list | grep {{ disk.dev }} | grep {{ osd.fs_type }}"

/var/lib/ceph/osd/ceph-{{ id }}:
  mount.mounted:
  - device: {{ disk.dev }}
  - fstype: {{ osd.fs_type }}
  - opts: {{ disk.get('opts', 'rw,noatime,inode64,logbufs=8,logbsize=256k') }} 
  - mkmnt: True

permission_/var/lib/ceph/osd/ceph-{{ id }}:
  file.directory:
    - name: /var/lib/ceph/osd/ceph-{{ id }}
    - user: ceph
    - group: ceph
    - mode: 755
    - makedirs: false
    - require:
      - mount: /var/lib/ceph/osd/ceph-{{ id }}
  
{{ disk.journal }}:
  file.managed:
  - user: ceph
  - group: ceph
  - replace: false

create_disk_{{ id }}:
  cmd.run:
  - name: "ceph-osd  -i {{ id }} --conf /etc/ceph/ceph.conf --mkfs --mkkey --mkjournal --setuser ceph"
  - unless: "test -f /var/lib/ceph/osd/ceph-{{ id }}/fsid"
  - require:
    - file: /var/lib/ceph/osd/ceph-{{ id }}
    - mount: /var/lib/ceph/osd/ceph-{{ id }}

add_keyring_{{ id }}:
  cmd.run:
  - name: "ceph auth add osd.{{ id }} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-{{ id }}/keyring"
  - unless: "ceph auth list | grep '^osd.{{ id }}'"
  - require:
    - cmd: create_disk_{{ id }}

/var/lib/ceph/osd/ceph-{{ id }}/done:
  file.managed:
  - content: {}
  - require:
    - cmd: add_keyring_{{ id }}

osd_services_{{ id }}_osd:
  service.running:
  - enable: true
  - names: ['ceph-osd@{{ id }}']
  - watch:
    - file: /etc/ceph/ceph.conf
  - require:
    - file: /var/lib/ceph/osd/ceph-{{ id }}/done
    - service: osd_services_perms

{% endfor %}


osd_services_global:
  service.running:
  - enable: true
  - names: ['ceph-osd.target']
  - watch:
    - file: /etc/ceph/ceph.conf

osd_services:
  service.running:
  - enable: true
  - names: ['ceph.target']
  - watch:
    - file: /etc/ceph/ceph.conf

/etc/systemd/system/ceph-osd-perms.service:
  file.managed:
    - contents: |
        [Unit]
        Description=Set OSD journals owned by ceph user
        After=local-fs.target
        Before=ceph-osd.target

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/bin/bash -c "chown -v ceph $(cat /etc/ceph/ceph.conf | grep 'osd journal' | awk '{print $4}')"

        [Install]
        WantedBy=multi-user.target

osd_services_perms:
  service.running:
  - enable: true
  - names: ['ceph-osd-perms']
  - require:
    - file: /etc/systemd/system/ceph-osd-perms.service