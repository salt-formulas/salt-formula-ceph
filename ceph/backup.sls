{%- from "ceph/map.jinja" import backup with context %}

{%- if backup.client is defined %}

{%- if backup.client.enabled %}

ceph_backup_client_packages:
  pkg.installed:
  - names: {{ backup.pkgs }}

ceph_backup_runner_script:
  file.managed:
  - name: /usr/local/bin/ceph-backup-runner.sh
  - source: salt://ceph/files/backup/ceph-backup-client-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: ceph_backup_client_packages

ceph_call_backup_runner_script:
  file.managed:
  - name: /usr/local/bin/ceph-backup-runner-call.sh
  - source: salt://ceph/files/backup/ceph-backup-client-runner-call.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: ceph_backup_client_packages

ceph_backup_dir:
  file.directory:
  - name: {{ backup.backup_dir }}/full
  - user: root
  - group: root
  - makedirs: true

ceph_backup_runner_cron:
  cron.present:
  - name: /usr/local/bin/ceph-backup-runner-call.sh
  - user: root
{%- if not backup.cron %}
  - commented: True
{%- endif %}
  - minute: random
{%- if backup.client.hours_before_full is defined %}
{%- if backup.client.hours_before_full <= 23 and backup.client.hours_before_full > 1 %}
  - hour: '*/{{ backup.client.hours_before_full }}'
{%- elif not backup.client.hours_before_full <= 1 %}
  - hour: 2
{%- endif %}
{%- else %}
  - hour: 2
{%- endif %}
  - require:
    - file: ceph_backup_runner_script
    - file: ceph_call_backup_runner_script


{%- endif %}

{%- endif %}

{%- if backup.server is defined %}

{%- if backup.server.enabled %}

ceph_backup_server_packages:
  pkg.installed:
  - names: {{ backup.pkgs }}

ceph_user:
  user.present:
  - name: ceph
  - system: true
  - home: {{ backup.backup_dir }}

{{ backup.backup_dir }}/full:
  file.directory:
  - mode: 755
  - user: ceph
  - group: ceph
  - makedirs: true
  - require:
    - user: ceph_user
    - pkg: ceph_backup_server_packages

{%- for key_name, key in backup.server.key.iteritems() %}

{%- if key.get('enabled', False) %}

ceph_key_{{ key.key }}:
  ssh_auth.present:
  - user: ceph
  - name: {{ key.key }}
  - require:
    - file: {{ backup.backup_dir }}/full


{%- endif %}

{%- endfor %}

ceph_server_script:
  file.managed:
  - name: /usr/local/bin/ceph-backup-runner.sh
  - source: salt://ceph/files/backup/ceph-backup-server-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: ceph_backup_server_packages

ceph_server_cron:
  cron.present:
  - name: /usr/local/bin/ceph-backup-runner.sh
  - user: ceph
{%- if not backup.cron %}
  - commented: True
{%- endif %}
  - minute: random
{%- if backup.server.hours_before_full is defined %}
{%- if backup.server.hours_before_full <= 23 and backup.server.hours_before_full > 1 %}
  - hour: '*/{{ backup.server.hours_before_full }}'
{%- elif not backup.server.hours_before_full <= 1 %}
  - hour: 2
{%- endif %}
{%- else %}
  - hour: 2
{%- endif %}
  - require:
    - file: ceph_server_script

{%- endif %}

{%- endif %}
