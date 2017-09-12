
============
Ceph formula
============

Ceph provides extraordinary data storage scalability. Thousands of client
hosts or KVMs accessing petabytes to exabytes of data. Each one of your
applications can use the object, block or file system interfaces to the same
RADOS cluster simultaneously, which means your Ceph storage system serves as a
flexible foundation for all of your data storage needs.

Use salt-formula-linux for initial disk partitioning.


Sample pillars
==============

Common metadata for all nodes/roles

.. code-block:: yaml

    ceph:
      common:
        version: kraken
        config:
          global:
            param1: value1
            param2: value1
            param3: value1
          pool_section:
            param1: value2
            param2: value2
            param3: value2
        fsid: a619c5fc-c4ed-4f22-9ed2-66cf2feca23d
        members:
        - name: cmn01
          host: 10.0.0.1
        - name: cmn02
          host: 10.0.0.2
        - name: cmn03
          host: 10.0.0.3
        keyring:
          admin:
            key: AQBHPYhZv5mYDBAAvisaSzCTQkC5gywGUp/voA==
            caps:
              mds: "allow *"
              mgr: "allow *"
              mon: "allow *"
              osd: "allow *"

Optional definition for cluster and public networks. Cluster network is used
for replication. Public network for front-end communication.

.. code-block:: yaml

    ceph:
      common:
        version: kraken
        fsid: a619c5fc-c4ed-4f22-9ed2-66cf2feca23d
        ....
        public_network: 10.0.0.0/24, 10.1.0.0/24
        cluster_network: 10.10.0.0/24, 10.11.0.0/24


Ceph mon (control) roles
------------------------

Monitors: A Ceph Monitor maintains maps of the cluster state, including the
monitor map, the OSD map, the Placement Group (PG) map, and the CRUSH map.
Ceph maintains a history (called an “epoch”) of each state change in the Ceph
Monitors, Ceph OSD Daemons, and PGs.

.. code-block:: yaml

    ceph:
      common:
        config:
          mon:
            key: value
      mon:
        enabled: true
        keyring:
          mon:
            key: AQAnQIhZ6in5KxAAdf467upoRMWFcVg5pbh1yg==
            caps:
              mon: "allow *"
          admin:
            key: AQBHPYhZv5mYDBAAvisaSzCTQkC5gywGUp/voA==
            caps:
              mds: "allow *"
              mgr: "allow *"
              mon: "allow *"
              osd: "allow *"

Ceph mgr roles
------------------------

The Ceph Manager daemon (ceph-mgr) runs alongside monitor daemons, to provide additional monitoring and interfaces to external monitoring and management systems. Since the 12.x (luminous) Ceph release, the ceph-mgr daemon is required for normal operations. The ceph-mgr daemon is an optional component in the 11.x (kraken) Ceph release.

By default, the manager daemon requires no additional configuration, beyond ensuring it is running. If there is no mgr daemon running, you will see a health warning to that effect, and some of the other information in the output of ceph status will be missing or stale until a mgr is started.


.. code-block:: yaml

    ceph:
      mgr:
        enabled: true
        dashboard:
          enabled: true
          host: 10.103.255.252
          port: 7000


Ceph OSD (storage) roles
------------------------

.. code-block:: yaml

    ceph:
      common:
        config:
          osd:
            key: value
      osd:
        enabled: true
        host_id: 10
        copy_admin_key: true
        journal_type: raw
        dmcrypt: disable
        osd_scenario: raw_journal_devices
        fs_type: xfs
        disk:
          '00':
            rule: hdd
            dev: /dev/vdb2
            journal: /dev/vdb1
            class: besthdd
            weight: 1.5
          '01':
            rule: hdd
            dev: /dev/vdc2
            journal: /dev/vdc1
            class: besthdd
            weight: 1.5
          '02':
            rule: hdd
            dev: /dev/vdd2
            journal: /dev/vdd1
            class: besthdd
            weight: 1.5


Ceph client roles
-----------------

Simple ceph client service

.. code-block:: yaml

    ceph:
      client:
        config:
          global:
            mon initial members: ceph1,ceph2,ceph3
            mon host: 10.103.255.252:6789,10.103.255.253:6789,10.103.255.254:6789
        keyring:
          monitoring:
            key: 00000000000000000000000000000000000000==

At OpenStack control settings are usually located at cinder-volume or glance-
registry services.

.. code-block:: yaml

    ceph:
      client:
        config:
          global:
            fsid: 00000000-0000-0000-0000-000000000000
            mon initial members: ceph1,ceph2,ceph3
            mon host: 10.103.255.252:6789,10.103.255.253:6789,10.103.255.254:6789
            osd_fs_mkfs_arguments_xfs:
            osd_fs_mount_options_xfs: rw,noatime
            network public: 10.0.0.0/24
            network cluster: 10.0.0.0/24
            osd_fs_type: xfs
          osd:
            osd journal size: 7500
            filestore xattr use omap: true
          mon:
            mon debug dump transactions: false
        keyring:
          cinder:
            key: 00000000000000000000000000000000000000==
          glance:
            key: 00000000000000000000000000000000000000==


Ceph gateway
------------

Rados gateway with keystone v2 auth backend

.. code-block:: yaml

    ceph:
      radosgw:
        enabled: true
        hostname: gw.ceph.lab
        bind:
          address: 10.10.10.1
          port: 8080
        identity:
          engine: keystone
          api_version: 2
          host: 10.10.10.100
          port: 5000
          user: admin
          password: password
          tenant: admin

Rados gateway with keystone v3 auth backend

.. code-block:: yaml

    ceph:
      radosgw:
        enabled: true
        hostname: gw.ceph.lab
        bind:
          address: 10.10.10.1
          port: 8080
        identity:
          engine: keystone
          api_version: 3
          host: 10.10.10.100
          port: 5000
          user: admin
          password: password
          project: admin
          domain: default


Ceph setup role
---------------

Replicated ceph storage pool

.. code-block:: yaml

    ceph:
      setup:
        pool:
          replicated_pool:
            pg_num: 256
            pgp_num: 256
            type: replicated
            crush_ruleset_name: 0

Erasure ceph storage pool

.. code-block:: yaml

    ceph:
      setup:
        pool:
          erasure_pool:
            pg_num: 256
            pgp_num: 256
            type: erasure
            crush_ruleset_name: 0

Generate CRUSH map
+++++++++++++++++++

It is required to define the `type` for crush buckets and these types must start with `root` (top) and end with `host`. OSD daemons will be assigned to hosts according to it's hostname. Weight of the buckets will be calculated according to weight of it's childen.

.. code-block:: yaml

  ceph:
    setup:
      crush:
        enabled: True
        tunables:
          choose_total_tries: 50
        type:
          - root
          - region
          - rack
          - host
        root:
          - name: root1
          - name: root2
        region:
          - name: eu-1
            parent: root1
          - name: eu-2
            parent: root1
          - name: us-1
            parent: root2
        rack:
          - name: rack01
            parent: eu-1
          - name: rack02
            parent: eu-2
          - name: rack03
            parent: us-1
        rule:
          sata:
            ruleset: 0
            type: replicated
            min_size: 1
            max_size: 10
            steps:
              - take crushroot.performanceblock.satahss.1
              - choseleaf firstn 0 type failure_domain
              - emit

Ceph monitoring
---------------

Collect general cluster metrics

.. code-block:: yaml

    ceph:
      monitoring:
        cluster_stats:
          enabled: true
          ceph_user: monitoring

Collect metrics from monitor and OSD services

.. code-block:: yaml

    ceph:
      monitoring:
        node_stats:
          enabled: true


More information
================

* https://github.com/cloud-ee/ceph-salt-formula
* http://ceph.com/ceph-storage/
* http://ceph.com/docs/master/start/intro/


Documentation and bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-ceph/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-ceph

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
