========
CEPH RBD
========

Ceph’s RADOS provides you with extraordinary data storage scalability—thousands of client hosts or KVMs accessing petabytes to exabytes of data. Each one of your applications can use the object, block or file system interfaces to the same RADOS cluster simultaneously, which means your Ceph storage system serves as a flexible foundation for all of your data storage needs.

Install and configure the Ceph MON and ODS services



Sample pillars
==============

Ceph OSDs: A Ceph OSD Daemon (Ceph OSD) stores data, handles data replication, recovery, backfilling, rebalancing, and provides some monitoring information to Ceph Monitors by checking other Ceph OSD Daemons for a heartbeat. A Ceph Storage Cluster requires at least two Ceph OSD Daemons to achieve an active + clean state when the cluster makes two copies of your data (Ceph makes 2 copies by default, but you can adjust it).

.. code-block:: yaml

    ceph:
      osd:
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

Monitors: A Ceph Monitor maintains maps of the cluster state, including the monitor map, the OSD map, the Placement Group (PG) map, and the CRUSH map. Ceph maintains a history (called an “epoch”) of each state change in the Ceph Monitors, Ceph OSD Daemons, and PGs.

.. code-block:: yaml

    ceph:
      mon:
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

Client pillar - ussually located at cinder-volume or glance-registry.

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

Read more
=========

* https://github.com/cloud-ee/ceph-salt-formula
* http://ceph.com/ceph-storage/
* http://ceph.com/docs/master/start/intro/
