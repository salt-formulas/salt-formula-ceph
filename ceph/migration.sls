# This script is used only for migration from Decapod deployed Ceph envs to salt-formula-ceph managed Ceph envs.

{%- if pillar.ceph.get('decapod') %}

packages:
  pkg.installed:
  - names:
    - git
    - gcc
    - libssl-dev
    - libyaml-dev
    - python
    - python-pip
    - python-setuptools
    - python-wheel

migration_script:
  file.managed:
  - name: /root/decapod_migration.py
  - source: salt://ceph/files/migration
  - require:
    - pkg: packages

git_clone_decapod:
  cmd.run:
  - name: "git clone -b stable-1.1 --depth 1 https://github.com/Mirantis/ceph-lcm.git /root/decapod"
  - unless: "test -d /root/decapod"
  - require:
    - pkg: packages
    - file: migration_script

install_decapodlib:
  cmd.run:
  - name: "pip2 install /root/decapod/decapodlib"
  - unless: "pip2 list | grep decapod"
  - require:
    - pkg: packages
    - file: migration_script
    - cmd: git_clone_decapod

run_migration_script:
  cmd.run:
  - name: "python decapod_migration.py {{ pillar.ceph.decapod.ip }} {{ pillar.ceph.decapod.user }} {{ pillar.ceph.decapod.password }} {{ pillar.ceph.decapod.deploy_config_name }}"
  - require:
    - pkg: packages
    - file: migration_script
    - cmd: git_clone_decapod
    - cmd: install_decapodlib

{%- endif %}
