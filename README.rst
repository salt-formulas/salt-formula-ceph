Ceph formula
============

.. contents::
    :depth: 2

Introduction
============

Ceph provides extraordinary data storage scalability. Thousands of client
hosts or KVMs accessing petabytes to exabytes of data. Each one of your
applications can use the object, block or file system interfaces to the same
RADOS cluster simultaneously, which means your Ceph storage system serves as a
flexible foundation for all of your data storage needs.

Use salt-formula-linux for initial disk partitioning.

Daemons
--------

Ceph uses several daemons to handle data and cluster state. Each daemon type requires different computing capacity and hardware optimization.

These daemons are currently supported by formula:

* MON (`ceph.mon`)
* OSD (`ceph.osd`)
* RGW (`ceph.radosgw`)


Architecture decisions
-----------------------

Please refer to upstream achritecture documents before designing your cluster. Solid understanding of Ceph principles is essential for making architecture decisions described bellow.
http://docs.ceph.com/docs/master/architecture/

* Ceph version

There is 3 or 4 stable releases every year and many of nighty/dev release. You should decide which version will be used since the only stable releases are recommended for production. Some of the releases are marked LTS (Long Term Stable) and these releases receive bugfixed for longer period - usually until next LTS version is released.

* Number of MON daemons

Use 1 MON daemon for testing, 3 MONs for smaller production clusters and 5 MONs for very large production cluster. There is no need to have more than 5 MONs in normal environment because there isn't any significant benefit in running more than 5 MONs. Ceph require MONS to form quorum so you need to heve more than 50% of the MONs up and running to have fully operational cluster. Every I/O operation will stop once less than 50% MONs is availabe because they can't form quorum.

* Number of PGs

Placement groups are providing mappping between stored data and OSDs. It is necessary to calculate number of PGs because there should be stored decent amount of PGs on each OSD. Please keep in mind *decreasing number of PGs* isn't possible and *increading* can affect cluster performance.

http://docs.ceph.com/docs/master/rados/operations/placement-groups/
http://ceph.com/pgcalc/

* Daemon colocation

It is recommended to dedicate nodes for MONs and RWG since colocation can have and influence on cluster operations. Howerver, small clusters can be running MONs on OSD node but it is critical to have enough of resources for MON daemons because they are the most important part of the cluster.

Installing RGW on node with other daemons isn't recommended because RGW daemon usually require a lot of bandwith and it harm cluster health.

* Store type (Bluestore/Filestore)

Recent version of Ceph support Bluestore as storage backend and backend should be used if available.

http://docs.ceph.com/docs/master/rados/configuration/bluestore-config-ref/

* Block.db location for Bluestore

There are two ways to setup block.db:
  * **Colocated** block.db partition is created on the same disk as partition for the data. This setup is easier for installation and it doesn't require any other disk to be used. However, colocated setup is significantly slower than dedicated)
  * **Dedicate** block.db is placed on different disk than data (or into partition). This setup can deliver much higher performance than colocated but it require to have more disks in servers. Block.db drives should be carefully selected because high I/O and durability is required.

* Block.wal location for Bluestore

There are two ways to setup block.wal - stores just the internal journal (write-ahead log):
  * **Colocated** block.wal uses free space of the block.db device.
  * **Dedicate** block.wal is placed on different disk than data (better put into partition as the size can be small) and possibly block.db device. This setup can deliver much higher performance than colocated but it require to have more disks in servers. Block.wal drives should be carefully selected because high I/O and durability is required.

* Journal location for Filestore

There are two ways to setup journal:
  * **Colocated** journal is created on the same disk as partition for the data. This setup is easier for installation and it doesn't require any other disk to be used. However, colocated setup is significantly slower than dedicated)
  * **Dedicate** journal is placed on different disk than data (or into partition). This setup can deliver much higher performance than colocated but it require to have more disks in servers. Journal drives should be carefully selected because high I/O and durability is required.

* Cluster and public network

Ceph cluster is accessed using network and thus you need to have decend capacity to handle all the client. There are two networks required for cluster: **public** network and cluster network. Public network is used for client connections and MONs and OSDs are listening on this network. Second network ic called **cluster** networks and this network is used for communication between OSDs.

Both networks should have dedicated interfaces, bonding interfaces and dedicating vlans on bonded interfaces isn't allowed. Good practise is dedicate more throughput for the cluster network because cluster traffic is more important than client traffic.

* Pool parameters (size, min_size, type)

You should setup each pool according to it's expected usage, at least `min_size` and `size` and pool type should be considered.

* Cluster monitoring

* Hardware

Please refer to upstream hardware recommendation guide for general information about hardware.

Ceph servers are required to fulfil special requirements becauce load generated by Ceph can be diametrically opposed to common load.

http://docs.ceph.com/docs/master/start/hardware-recommendations/


Basic management commands
------------------------------

Cluster
=======

- :code:`ceph health` - check if cluster is healthy (:code:`ceph health detail` can provide more information)


.. code-block:: bash

  root@c-01:~# ceph health
  HEALTH_OK

- :code:`ceph status` - shows basic information about cluster


.. code-block:: bash

  root@c-01:~# ceph status
      cluster e2dc51ae-c5e4-48f0-afc1-9e9e97dfd650
       health HEALTH_OK
       monmap e1: 3 mons at {1=192.168.31.201:6789/0,2=192.168.31.202:6789/0,3=192.168.31.203:6789/0}
              election epoch 38, quorum 0,1,2 1,2,3
       osdmap e226: 6 osds: 6 up, 6 in
        pgmap v27916: 400 pgs, 2 pools, 21233 MB data, 5315 objects
              121 GB used, 10924 GB / 11058 GB avail
                   400 active+clean
    client io 481 kB/s rd, 132 kB/s wr, 185 op/

MON
---

http://ceph.com/docs/master/rados/troubleshooting/troubleshooting-mon/

OSD
---

http://ceph.com/docs/master/rados/troubleshooting/troubleshooting-osd/

- :code:`ceph osd tree` - show all OSDs and it's state

.. code-block:: bash

  root@c-01:~# ceph osd tree
  ID WEIGHT   TYPE NAME     UP/DOWN REWEIGHT PRIMARY-AFFINITY
  -4        0 host c-04
  -1 10.79993 root default
  -2  3.59998     host c-01
   0  1.79999         osd.0      up  1.00000          1.00000
   1  1.79999         osd.1      up  1.00000          1.00000
  -3  3.59998     host c-02
   2  1.79999         osd.2      up  1.00000          1.00000
   3  1.79999         osd.3      up  1.00000          1.00000
  -5  3.59998     host c-03
   4  1.79999         osd.4      up  1.00000          1.00000
   5  1.79999         osd.5      up  1.00000          1.00000

- :code:`ceph osd pools ls` - list of pool

.. code-block:: bash

  root@c-01:~# ceph osd lspools
  0 rbd,1 test

PG
--

http://ceph.com/docs/master/rados/troubleshooting/troubleshooting-pg

- :code:`ceph pg ls` - list placement groups

.. code-block:: bash

  root@c-01:~# ceph pg ls | head -n 4
  pg_stat	objects	mip	degr	misp	unf	bytes	log	disklog	state	state_stamp	v	reported	up	up_primary	acting	acting_primary	last_scrub	scrub_stamp	last_deep_scrub	deep_scrub_stamp
  0.0	11	0	0	0	0	46137344	3044	3044	active+clean	2015-07-02 10:12:40.603692	226'10652	226:1798	[4,2,0]	4	[4,2,0]	4	0'0	2015-07-01 18:38:33.126953	0'0	2015-07-01 18:17:01.904194
  0.1	7	0	0	0	0	25165936	3026	3026	active+clean	2015-07-02 10:12:40.585833	226'5808	226:1070	[2,4,1]	2	[2,4,1]	2	0'0	2015-07-01 18:38:32.352721	0'0	2015-07-01 18:17:01.904198
  0.2	18	0	0	0	0	75497472	3039	3039	active+clean	2015-07-02 10:12:39.569630	226'17447	226:3213	[3,1,5]	3	[3,1,5]	3	0'0	2015-07-01 18:38:34.308228	0'0	2015-07-01 18:17:01.904199

- :code:`ceph pg map 1.1` - show mapping between PG and OSD

.. code-block:: bash

  root@c-01:~# ceph pg map 1.1
  osdmap e226 pg 1.1 (1.1) -> up [5,1,2] acting [5,1,2]



Sample pillars
==============

Common metadata for all nodes/roles

.. code-block:: yaml

    ceph:
      common:
        version: luminous
        cluster_name: ceph
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
            caps:
              mds: "allow *"
              mgr: "allow *"
              mon: "allow *"
              osd: "allow *"
          bootstrap-osd:
            caps:
              mon: "allow profile bootstrap-osd"


Optional definition for cluster and public networks. Cluster network is used
for replication. Public network for front-end communication.

.. code-block:: yaml

    ceph:
      common:
        version: luminous
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
            caps:
              mon: "allow *"
          admin:
            caps:
              mds: "allow *"
              mgr: "allow *"
              mon: "allow *"
              osd: "allow *"

Ceph mgr roles
--------------

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
        version: luminous
        fsid: a619c5fc-c4ed-4f22-9ed2-66cf2feca23d
        public_network: 10.0.0.0/24, 10.1.0.0/24
        cluster_network: 10.10.0.0/24, 10.11.0.0/24
        keyring:
          bootstrap-osd:
            caps:
              mon: "allow profile bootstrap-osd"
          ....
      osd:
        enabled: true
        crush_parent: rack01
        journal_size: 20480                     (20G)
        bluestore_block_db_size: 10073741824    (10G)
        bluestore_block_wal_size: 10073741824   (10G)
        bluestore_block_size: 807374182400     (800G)
        backend:
          filestore:
            disks:
            - dev: /dev/sdm
              enabled: false
              journal: /dev/ssd
              journal_partition: 5
              data_partition: 6
              lockbox_partition: 7
              data_partition_size: 12000        (MB)
              class: bestssd
              weight: 1.666
              dmcrypt: true
              journal_dmcrypt: false
            - dev: /dev/sdf
              journal: /dev/ssd
              journal_dmcrypt: true
              class: bestssd
              weight: 1.666
            - dev: /dev/sdl
              journal: /dev/ssd
              class: bestssd
              weight: 1.666
          bluestore:
            disks:
            - dev: /dev/sdb
            - dev: /dev/sdf
              block_db: /dev/ssd
              block_wal: /dev/ssd
              block_db_dmcrypt: true
              block_wal_dmcrypt: true
            - dev: /dev/sdc
              block_db: /dev/ssd
              block_wal: /dev/ssd
              data_partition: 1
              block_partition: 2
              lockbox_partition: 5
              block_db_partition: 3
              block_wal_partition: 4
              class: ssd
              weight: 1.666
              dmcrypt: true
              block_db_dmcrypt: false
              block_wal_dmcrypt: false
            - dev: /dev/sdd
              enabled: false


Ceph client roles - ...Deprecated - use ceph:common instead
-----------------------------------------------------------

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
      common:
        config:
          rgw:
            key: value
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
        swift:
          versioning:
            enabled: true


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
            crush_rule: sata
            application: rbd

  .. note:: For Kraken and earlier releases please specify crush_rule as a ruleset number.
            For Kraken and earlier releases application param is not needed.

Erasure ceph storage pool

.. code-block:: yaml

    ceph:
      setup:
        pool:
          erasure_pool:
            pg_num: 256
            pgp_num: 256
            type: erasure
            crush_rule: ssd
            application: rbd


Inline compression for Bluestore backend

.. code-block:: yaml

    ceph:
      setup:
        pool:
          volumes:
            pg_num: 256
            pgp_num: 256
            type: replicated
            crush_rule: hdd
            application: rbd
            compression_algorithm: snappy
            compression_mode: aggressive
            compression_required_ratio: .875
            ...


Ceph manage keyring keys
------------------------

Keyrings are dynamically generated unless specified by the following pillar.

.. code-block:: yaml

    ceph:
      common:
        manage_keyring: true
        keyring:
          glance:
            name: images
            key: AACf3ulZFFPNDxAAd2DWds3aEkHh4IklZVgIaQ==
            caps:
              mon: "allow r"
              osd: "allow class-read object_prefix rdb_children, allow rwx pool=images"


Generate CRUSH map - Recommended way
------------------------------------

It is required to define the `type` for crush buckets and these types must start with `root` (top) and end with `host`. OSD daemons will be assigned to hosts according to it's hostname. Weight of the buckets will be calculated according to weight of it's children.

If the pools that are in use have size of 3 it is best to have 3 children of a specific type in the root CRUSH tree to replicate objects across (Specified in rule steps by 'type region').

.. code-block:: yaml

    ceph:
      setup:
        crush:
          enabled: True
          tunables:
            choose_total_tries: 50
            choose_local_tries: 0
            choose_local_fallback_tries: 0
            chooseleaf_descend_once: 1
            chooseleaf_vary_r: 1
            chooseleaf_stable: 1
            straw_calc_version: 1
            allowed_bucket_algs: 54
          type:
            - root
            - region
            - rack
            - host
            - osd
          root:
            - name: root-ssd
            - name: root-sata
          region:
            - name: eu-1
              parent: root-sata
            - name: eu-2
              parent: root-sata
            - name: eu-3
              parent: root-ssd
            - name: us-1
              parent: root-sata
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
                - take take root-ssd
                - chooseleaf firstn 0 type region
                - emit
            ssd:
              ruleset: 1
              type: replicated
              min_size: 1
              max_size: 10
              steps:
                - take take root-sata
                - chooseleaf firstn 0 type region
                - emit


Generate CRUSH map - Alternative way
------------------------------------

It's necessary to create per OSD pillar.

.. code-block:: yaml

    ceph:
      osd:
        crush:
          - type: root
            name: root1
          - type: region
            name: eu-1
          - type: rack
            name: rack01
          - type: host
            name: osd001

Add OSDs with specific weight
-----------------------------

Add OSD device(s) with initial weight set specifically to certain value.

.. code-block:: yaml

    ceph:
      osd:
        crush_initial_weight: 0


Apply CRUSH map
---------------

Before you apply CRUSH map please make sure that settings in generated file in /etc/ceph/crushmap are correct.

.. code-block:: yaml

    ceph:
      setup:
        crush:
          enforce: true
        pool:
          images:
            crush_rule: sata
            application: rbd
          volumes:
            crush_rule: sata
            application: rbd
          vms:
            crush_rule: ssd
            application: rbd

  .. note:: For Kraken and earlier releases please specify crush_rule as a ruleset number.
            For Kraken and earlier releases application param is not needed.


Persist CRUSH map
-----------------

After the CRUSH map is applied to Ceph it's recommended to persist the same settings even after OSD reboots.

.. code-block:: yaml

    ceph:
      osd:
        crush_update: false


Ceph monitoring
---------------

By default monitoring is setup to collect information from MON and OSD nodes. To change the default values add the following pillar to MON nodes.

.. code-block:: yaml

    ceph:
      monitoring:
        space_used_warning_threshold: 0.75
        space_used_critical_threshold: 0.85
        apply_latency_threshold: 0.007
        commit_latency_threshold: 0.7
        pool:
          vms:
            pool_space_used_utilization_warning_threshold: 0.75
            pool_space_used_critical_threshold: 0.85
            pool_write_ops_threshold: 200
            pool_write_bytes_threshold: 70000000
            pool_read_bytes_threshold: 70000000
            pool_read_ops_threshold: 1000
          images:
            pool_space_used_utilization_warning_threshold: 0.50
            pool_space_used_critical_threshold: 0.95
            pool_write_ops_threshold: 100
            pool_write_bytes_threshold: 50000000
            pool_read_bytes_threshold: 50000000
            pool_read_ops_threshold: 500

Ceph monitor backups
--------------------

Backup client with ssh/rsync remote host

.. code-block:: yaml

    ceph:
      backup:
        client:
          enabled: true
          full_backups_to_keep: 3
          hours_before_full: 24
          target:
            host: cfg01
            backup_dir: server-backup-dir

Backup client with local backup only

.. code-block:: yaml

    ceph:
      backup:
        client:
          enabled: true
          full_backups_to_keep: 3
          hours_before_full: 24


Backup client at exact times:

.. code-block:: yaml

  ceph:
    backup:
      client:
        enabled: true
        full_backups_to_keep: 3
        incr_before_full: 3
        backup_times:
          day_of_week: 0
          hour: 4
          minute: 52
        compression: true
        compression_threads: 2
        database:
          user: user
          password: password
        target:
          host: host01

  .. note:: Parameters in ``backup_times`` section can be used to set up exact
  time the cron job should be executed. In this example, the backup job
  would be executed every Sunday at 4:52 AM. If any of the individual
  ``backup_times`` parameters is not defined, the defalut ``*`` value will be
  used. For example, if minute parameter is ``*``, it will run the backup every minute,
  which is ususally not desired.
  Available parameters are ``day_of_week``, ``day_of_month``, ``month``, ``hour`` and ``minute``.
  Please see the crontab reference for further info on how to set these parameters.

  .. note:: Please be aware that only ``backup_times`` section OR
  ``hours_before_full(incr)`` can be defined. If both are defined,
  the ``backup_times`` section will be peferred.

  .. note:: New parameter ``incr_before_full`` needs to be defined. This
  number sets number of incremental backups to be run, before a full backup
  is performed.

Backup server rsync

.. code-block:: yaml

    ceph:
      backup:
        server:
          enabled: true
          hours_before_full: 24
          full_backups_to_keep: 5
          key:
            ceph_pub_key:
              enabled: true
              key: ssh_rsa

Backup server without strict client restriction

.. code-block:: yaml

    ceph:
      backup:
        restrict_clients: false

Backup server at exact times:

.. code-block:: yaml

  ceph:
    backup:
      server:
        enabled: true
        full_backups_to_keep: 3
        incr_before_full: 3
        backup_dir: /srv/backup
        backup_times:
          day_of_week: 0
          hour: 4
          minute: 52
        key:
          ceph_pub_key:
            enabled: true
            key: key

  .. note:: Parameters in ``backup_times`` section can be used to set up exact
  time the cron job should be executed. In this example, the backup job
  would be executed every Sunday at 4:52 AM. If any of the individual
  ``backup_times`` parameters is not defined, the defalut ``*`` value will be
  used. For example, if minute parameter is ``*``, it will run the backup every minute,
  which is ususally not desired.
  Available parameters are ``day_of_week``, ``day_of_month``, ``month``, ``hour`` and ``minute``.
  Please see the crontab reference for further info on how to set these parameters.

  .. note:: Please be aware that only ``backup_times`` section OR
  ``hours_before_full(incr)`` can be defined. If both are defined, The
  ``backup_times`` section will be peferred.

  .. note:: New parameter ``incr_before_full`` needs to be defined. This
  number sets number of incremental backups to be run, before a full backup
  is performed.

Migration from Decapod to salt-formula-ceph
-------------------------------------------

The following configuration will run a python script which will generate ceph config and osd disk mappings to be put in cluster model.

.. code-block:: yaml

    ceph:
      decapod:
        ip: 192.168.1.10
        user: user
        password: psswd
        deploy_config_name: ceph


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
