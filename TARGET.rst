Proposal
=========

Ceph salt formula should be able to provide these tasks:

* initial deploy of Ceph cluster
* remove broken OSD
* add new OSD
* add new node with OSDs



Test procedure
---------------

. Bootstrap nodes
. Deploy 3 MON nodes
. Deploy 3 OSD nodes
. Deploy 1 MDS
. Deploy client
. Run tests:

* Ceph is healty
* There are 3 MONs and 3 OSD nodes

* Create RBD, map it, mount it, write testing file, get output, unmount, unmap, remove
* Create CephFS, mount it, write file, unmount it
