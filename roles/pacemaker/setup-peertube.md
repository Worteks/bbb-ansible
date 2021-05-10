# Setting up PeerTube on Scalelite App

```sh
[enter corosync CLI: crm configure]
crm(live/peertube-2.example.com)configure# primitive DRBD_r0 ocf:linbit:drbd params drbd_resource="videos" op start interval="0" timeout="240" op stop interval="0" timeout="100" op monitor role=Master interval=59s timeout=30s op monitor role=Slave interval=60s timeout=30s
crm(live/peertube-2.example.com)configure# primitive LVM_r0 ocf:heartbeat:LVM params volgrpname="data" op monitor interval="30s"
crm(live/peertube-2.example.com)configure# primitive SRV_MOUNT_1 ocf:heartbeat:Filesystem params device="/dev/mapper/data-peertube" directory="/var/lib/peertube/" fstype="xfs" options="noatime,nodiratime,noexec,nodev,nosuid" op monitor interval="40s"
crm(live/peertube-2.example.com)configure# primitive IP-rsc ocf:heartbeat:IPaddr2 params ip="192.168.255.52" nic="priv0" cidr_netmask="24" meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/peertube-2.example.com)configure# primitive Peertube-rsc systemd:peertube meta migration-threshold=2 op monitor interval=20 timeout=150 on-fail=restart
crm(live/peertube-2.example.com)configure# primitive Peertubexp-rsc systemd:peertube-exporter meta migration-threshold=2 op monitor interval=20 timeout=300 on-fail=restart
crm(live/peertube-2.example.com)configure# primitive Nginx-rsc lsb:nginx meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/peertube-2.example.com)configure# primitive Nginxxp-rsc systemd:nginx-exporter meta migration-threshold=2 op monitor interval=20 timeout=200 on-fail=restart
crm(live/peertube-2.example.com)configure# group APCLUSTER LVM_r0 SRV_MOUNT_1 IP-rsc Peertube-rsc Peertubexp-rsc Nginx-rsc Nginxxp-rsc
crm(live/peertube-2.example.com)configure# ms ms_DRBD_APCLUSTER DRBD_r0 meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
crm(live/peertube-2.example.com)configure# colocation APCLUSTER_on_DRBD_r0 inf: APCLUSTER ms_DRBD_APCLUSTER:Master
crm(live/peertube-2.example.com)configure# order APCLUSTER_after_DRBD_r0 inf: ms_DRBD_APCLUSTER:promote APCLUSTER:start
crm(live/peertube-2.example.com)configure# commit
ERROR: (unpack_config) 	warning: Blind faith: not fencing unseen nodes
(get_ordering_type) 	warning: Support for 'score' in rsc_order is deprecated and will be removed in a future release (use 'kind' instead)
Warnings found during check: config may not be valid
Do you still want to commit (y/n)? y
crm(live/peertube-2.example.com)configure# up
crm(live/peertube-2.example.com)# status
Stack: corosync
Current DC: peertube-1 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Wed Apr 21 17:11:45 2021
Last change: Wed Apr 21 17:11:28 2021 by root via cibadmin on peertube-2

2 nodes configured
9 resources configured

Online: [ peertube-1 peertube-2 ]

Full list of resources:

 Resource Group: APCLUSTER
     LVM_r0	(ocf::heartbeat:LVM):	Started peertube-2
     SRV_MOUNT_1	(ocf::heartbeat:Filesystem):	Started peertube-2
     IP-rsc	(ocf::heartbeat:IPaddr2):	Started peertube-2
     Peertube-rsc	(systemd:peertube):	Started peertube-2
     Peertubexp-rsc	(systemd:peertube-exporter):	Started peertube-2
     Nginx-rsc	(lsb:nginx):	Started peertube-2
     Nginxxp-rsc	(systemd:nginx-exporter):	Started peertube-2
 Clone Set: ms_DRBD_APCLUSTER [DRBD_r0] (promotable)
     Masters: [ peertube-2 ]
     Slaves: [ peertube-1 ]
```
