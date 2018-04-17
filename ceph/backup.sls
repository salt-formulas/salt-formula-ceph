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

{%- if backup.cron %}

ceph_backup_runner_cron:
  cron.present:
  - name: /usr/local/bin/ceph-backup-runner-call.sh
  - user: root
{%- if backup.client.backup_times is defined %}
{%- if backup.client.backup_times.dayOfWeek is defined %}
  - dayweek: {{ backup.client.backup_times.dayOfWeek }}
{%- endif -%}
{%- if backup.client.backup_times.month is defined %}
  - month: {{ backup.client.backup_times.month }}
{%- endif %}
{%- if backup.client.backup_times.dayOfMonth is defined %}
  - daymonth: {{ backup.client.backup_times.dayOfMonth }}
{%- endif %}
{%- if backup.client.backup_times.hour is defined %}
  - hour: {{ backup.client.backup_times.hour }}
{%- endif %}
{%- if backup.client.backup_times.minute is defined %}
  - minute: {{ backup.client.backup_times.minute }}
{%- endif %}
{%- elif backup.client.hours_before_incr is defined %}
  - minute: 0
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

{%- else %}

ceph_backup_runner_cron:
  cron.absent:
  - name: /usr/local/bin/ceph-backup-runner-call.sh
  - user: root

{%- endif %}

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

{{ backup.backup_dir }}/.ssh:
  file.directory:
  - mode: 700
  - user: ceph
  - group: ceph
  - require:
    - user: ceph_user

{{ backup.backup_dir }}/.ssh/authorized_keys:
  file.managed:
  - user: ceph
  - group: ceph
  - template: jinja
  - source: salt://ceph/files/backup/authorized_keys
  - require:
    - file: {{ backup.backup_dir }}/full
    - file: {{ backup.backup_dir }}/.ssh

ceph_server_script:
  file.managed:
  - name: /usr/local/bin/ceph-backup-runner.sh
  - source: salt://ceph/files/backup/ceph-backup-server-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: ceph_backup_server_packages

{%- if backup.cron %}

ceph_server_cron:
  cron.present:
  - name: /usr/local/bin/ceph-backup-runner.sh
  - user: ceph
{%- if backup.server.backup_times is defined %}
{%- if backup.server.backup_times.dayOfWeek is defined %}
  - dayweek: {{ backup.server.backup_times.dayOfWeek }}
{%- endif -%}
{%- if backup.server.backup_times.month is defined %}
  - month: {{ backup.server.backup_times.month }}
{%- endif %}
{%- if backup.server.backup_times.dayOfMonth is defined %}
  - daymonth: {{ backup.server.backup_times.dayOfMonth }}
{%- endif %}
{%- if backup.server.backup_times.hour is defined %}
  - hour: {{ backup.server.backup_times.hour }}
{%- endif %}
{%- if backup.server.backup_times.minute is defined %}
  - minute: {{ backup.server.backup_times.minute }}
{%- endif %}
{%- elif backup.server.hours_before_incr is defined %}
  - minute: 0
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

{%- else %}

ceph_server_cron:
  cron.absent:
  - name: /usr/local/bin/ceph-backup-runner.sh
  - user: ceph

{%- endif %}

{%- endif %}

{%- endif %}
