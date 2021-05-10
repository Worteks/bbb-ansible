# Setting up PaceMaker on Greenlight

```sh
[enter corosync CLI: crm configure]
crm(live/greenlight-1.example.com)configure# primitive DRBD_r0 ocf:linbit:drbd params drbd_resource="postgres" op start interval="0" timeout="240" op stop interval="0" timeout="100" op monitor role=Master interval=59s timeout=30s op monitor role=Slave interval=60s timeout=30s
crm(live/greenlight-1.example.com)configure# primitive LVM_r0 ocf:heartbeat:LVM params volgrpname="data" op monitor interval="30s"
crm(live/greenlight-1.example.com)configure# primitive SRV_MOUNT_1 ocf:heartbeat:Filesystem params device="/dev/mapper/data-postgres" directory="/var/lib/postgresql" fstype="xfs" options="noatime,nodiratime,noexec,nodev,nosuid" op monitor interval="40s"
crm(live/greenlight-1.example.com)configure# primitive IP-rsc ocf:heartbeat:IPaddr2 params ip="192.168.255.102" nic="priv0" cidr_netmask="24" meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/greenlight-1.example.com)configure# primitive Postgresql-rsc lsb:postgresql meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/greenlight-1.example.com)configure# group APCLUSTER LVM_r0 SRV_MOUNT_1 IP-rsc Postgresql-rsc
crm(live/greenlight-1.example.com)configure# ms ms_DRBD_APCLUSTER DRBD_r0 meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
crm(live/greenlight-1.example.com)configure# colocation APCLUSTER_on_DRBD_r0 inf: APCLUSTER ms_DRBD_APCLUSTER:Master
crm(live/greenlight-1.example.com)configure# order APCLUSTER_after_DRBD_r0 inf: ms_DRBD_APCLUSTER:promote APCLUSTER:start
crm(live/greenlight-1.example.com)configure# commit
ERROR: (unpack_config)  warning: Blind faith: not fencing unseen nodes
(get_ordering_type)     warning: Support for 'score' in rsc_order is deprecated and will be removed in a future release (use 'kind' instead)
Warnings found during check: config may not be valid
Do you still want to commit (y/n)? y
crm(live/greenlight-1.example.com)configure# up
crm(live/greenlight-1.example.com)# status
Stack: corosync
Current DC: greenlight-1 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Wed Apr 21 14:00:13 2021
Last change: Wed Apr 21 12:53:31 2021 by root via cibadmin on greenlight-1

2 nodes configured
6 resources configured

Online: [ greenlight-1 greenlight-2 ]

Full list of resources:

 Resource Group: APCLUSTER
     LVM_r0	(ocf::heartbeat:LVM):	Started greenlight-1
     SRV_MOUNT_1	(ocf::heartbeat:Filesystem):	Started greenlight-1
     IP-rsc	(ocf::heartbeat:IPaddr2):	Started greenlight-1
     Postgresql-rsc	(lsb:postgresql):	Started greenlight-1
 Clone Set: ms_DRBD_APCLUSTER [DRBD_r0] (promotable)
     Masters: [ greenlight-1 ]
     Slaves: [ greenlight-2 ]
```
