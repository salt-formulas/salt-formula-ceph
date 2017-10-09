{%- from "ceph/map.jinja" import common, mgr with context %}

{%- if mgr.get('enabled', False) %}

include:
- ceph.common

mon_packages:
  pkg.installed:
  - names: {{ mgr.pkgs }}

/etc/ceph/ceph.conf:
  file.managed:
  - source: salt://ceph/files/{{ common.version }}/ceph.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: mon_packages

/var/lib/ceph/mgr/ceph-{{ grains.host }}/:
  file.directory:
  - template: jinja
  - user: ceph
  - group: ceph
  - require:
    - pkg: mon_packages

reload_systemctl_daemon:
  cmd.run:
  - name: "systemctl daemon-reload"
  - unless: "test -f /var/lib/ceph/mgr/ceph-{{ grains.host }}/keyring"

ceph_create_mgr_keyring_{{ grains.host }}:
  cmd.run:
  - name: "ceph auth get-or-create mgr.{{ grains.host }} mon 'allow profile mgr' osd 'allow *' mds 'allow *' > /var/lib/ceph/mgr/ceph-{{ grains.host }}/keyring"
  - unless: "test -f /var/lib/ceph/mgr/ceph-{{ grains.host }}/keyring"
  - require:
    - file: /var/lib/ceph/mgr/ceph-{{ grains.host }}/

mgr_services:
  service.running:
    - enable: true
    - names: [ceph-mgr@{{ grains.host }}]
    - watch:
      - file: /etc/ceph/ceph.conf
    - require:
      - pkg: mon_packages
      - cmd: ceph_create_mgr_keyring_{{ grains.host }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- if mgr.get('dashboard', {}).get('enabled', False) %}

ceph_dashboard_address:
  cmd.run:
  - name: "ceph config-key put mgr/dashboard/{{ grains.host }}/server_addr {{ mgr.dashboard.get('host', '::') }}"
  - unless: "ceph config-key get mgr/dashboard/{{ grains.host }}/server_addr | grep {{ mgr.dashboard.get('host', '::') }}"

ceph_dashboard_port:
  cmd.run:
  - name: "ceph config-key put mgr/dashboard/{{ grains.host }}/server_port {{ mgr.dashboard.get('port', '7000') }}"
  - unless: "ceph config-key get mgr/dashboard/{{ grains.host }}/server_port | grep {{ mgr.dashboard.get('port', '7000') }}"


ceph_restart_dashboard_plugin:
  cmd.wait:
  - name: "ceph mgr module disable dashboard;ceph mgr module enable dashboard --force"
  - watch:
      - cmd: ceph_dashboard_address
      - cmd: ceph_dashboard_port

enable_ceph_dashboard:
  cmd.run:
  - name: "ceph mgr module enable dashboard"
  - unless: "ceph mgr module ls | grep dashboard"

{%- else %}

disable_ceph_dashboard:
  cmd.run:
  - name: "ceph mgr module disable dashboard"
  - onlyif: "ceph mgr module ls | grep dashboard"
  - require:
    - file: /var/lib/ceph/mgr/ceph-{{ grains.host }}/

{%- endif %}

{%- endif %}