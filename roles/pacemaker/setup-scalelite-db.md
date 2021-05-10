# Setting up PaceMaker on Scalelite DB

```sh
[enter corosync CLI: crm configure]
crm(live/scalelite-db-1.example.com)configure# primitive DRBD_r0 ocf:linbit:drbd params drbd_resource="postgres" op start interval="0" timeout="240" op stop interval="0" timeout="100" op monitor role=Master interval=59s timeout=30s op monitor role=Slave interval=60s timeout=30s
crm(live/scalelite-db-1.example.com)configure# primitive LVM_r0 ocf:heartbeat:LVM params volgrpname="data" op monitor interval="30s"
crm(live/scalelite-db-1.example.com)configure# primitive SRV_MOUNT_1 ocf:heartbeat:Filesystem params device="/dev/mapper/data-postgres" directory="/var/lib/postgresql" fstype="xfs" options="noatime,nodiratime,noexec,nodev,nosuid" op monitor interval="40s"
crm(live/scalelite-db-1.example.com)configure# primitive SRV_MOUNT_2 ocf:heartbeat:Filesystem params device="/dev/mapper/data-redis" directory="/var/lib/redis" fstype="xfs" options="noatime,nodiratime,noexec,nodev,nosuid" op monitor interval="40s"
crm(live/scalelite-db-1.example.com)configure# primitive IP-rsc ocf:heartbeat:IPaddr2 params ip="192.168.255.92" nic="priv0" cidr_netmask="24" meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/scalelite-db-1.example.com)configure# primitive Postgresql-rsc lsb:postgresql meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/scalelite-db-1.example.com)configure# primitive Redis-rsc lsb:redis-server meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/scalelite-db-1.example.com)configure# group APCLUSTER LVM_r0 SRV_MOUNT_1 SRV_MOUNT_2 IP-rsc Postgresql-rsc Redis-rsc
crm(live/scalelite-db-1.example.com)configure# ms ms_DRBD_APCLUSTER DRBD_r0 meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
crm(live/scalelite-db-1.example.com)configure# colocation APCLUSTER_on_DRBD_r0 inf: APCLUSTER ms_DRBD_APCLUSTER:Master
crm(live/scalelite-db-1.example.com)configure# order APCLUSTER_after_DRBD_r0 inf: ms_DRBD_APCLUSTER:promote APCLUSTER:start
crm(live/scalelite-db-1.example.com)configure# commit
ERROR: (unpack_config) 	warning: Blind faith: not fencing unseen nodes
(get_ordering_type) 	warning: Support for 'score' in rsc_order is deprecated and will be removed in a future release (use 'kind' instead)
Warnings found during check: config may not be valid
Do you still want to commit (y/n)? y
crm(live/scalelite-db-1.example.com)configure# up
crm(live/scalelite-db-1.example.com)# status
Stack: corosync
Current DC: scalelite-db-2 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Wed Apr 21 13:59:42 2021
Last change: Wed Apr 21 13:58:55 2021 by root via cibadmin on scalelite-db-1

2 nodes configured
8 resources configured

Online: [ scalelite-db-1 scalelite-db-2 ]

Full list of resources:

 Resource Group: APCLUSTER
     LVM_r0     (ocf::heartbeat:LVM):   Started scalelite-db-1
     SRV_MOUNT_1        (ocf::heartbeat:Filesystem):    Started scalelite-db-1
     SRV_MOUNT_2        (ocf::heartbeat:Filesystem):    Started scalelite-db-1
     IP-rsc     (ocf::heartbeat:IPaddr2):       Started scalelite-db-1
     Postgresql-rsc     (lsb:postgresql):       Started scalelite-db-1
     Redis-rsc  (lsb:redis-server):     Started scalelite-db-1
 Clone Set: ms_DRBD_APCLUSTER [DRBD_r0] (promotable)
     Masters: [ scalelite-db-1 ]
     Slaves: [ scalelite-db-2 ]
```
