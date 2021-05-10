# Setting up PaceMaker on Reverses

```sh
[enter corosync CLI: crm configure]
crm(live/reverse-1.example.com)configure# primitive IP-rsc ocf:heartbeat:IPaddr2 params ip="192.168.255.1" nic="priv0" cidr_netmask="24" meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/reverse-1.example.com)configure# commit
ERROR: (unpack_config) 	warning: Blind faith: not fencing unseen nodes
crm(live/reverse-1.example.com)configure# up
crm(live/reverse-1.example.com)# status
Stack: corosync
Current DC: pcm-1 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Fri May  7 20:15:15 2021
Last change: Tue May  4 19:00:34 2021 by root via cibadmin on pcm-2

2 nodes configured
1 resource configured

Online: [ pcm-1 pcm-2 ]

Full list of resources:

 IP-rsc	(ocf::heartbeat:IPaddr2):	Started pcm-1
```
