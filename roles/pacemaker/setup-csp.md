# Setting up PaceMaker on BBB-CSP

```sh
[enter corosync CLI: crm configure]
crm(live/csp-1.example.com)configure# primitive IP-rsc ocf:heartbeat:IPaddr2 params ip="192.168.255.42" nic="priv0" cidr_netmask="24" meta migration-threshold=2 op monitor interval=20 timeout=60 on-fail=restart
crm(live/csp-1.example.com)configure# commit
ERROR: (unpack_config) 	warning: Blind faith: not fencing unseen nodes
crm(live/csp-1.example.com)configure# up
crm(live/csp-1.example.com)# status
Stack: corosync
Current DC: csp-2 (version 2.0.1-9e909a5bdd) - partition with quorum
Last updated: Fri May  7 20:13:25 2021
Last change: Fri May  7 20:13:07 2021 by root via cibadmin on csp-1

2 nodes configured
1 resource configured

Online: [ csp-1 csp-2 ]

Full list of resources:

 IP-rsc	(ocf::heartbeat:IPaddr2):	Started csp-1
```
