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
  - minute: '*'
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

{%- set clients = [] %}
{%- if backup.restrict_clients %}
  {%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}
    {%- if node_grains.get('ceph_backup', {}).get('client') %}
    {%- set client = node_grains.get('ceph_backup').get('client') %}
      {%- if client.get('addresses') and client.get('addresses', []) is iterable %}
        {%- for address in client.addresses %}
          {%- do clients.append(address|string) %}
        {%- endfor %}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

ceph_key_{{ key.key }}:
  ssh_auth.present:
  - user: ceph
  - name: {{ key.key }}
  - options:
    - no-pty
{%- if clients %}
    - from="{{ clients|join(',') }}"
{%- endif %}
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
  - minute: '*'
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
