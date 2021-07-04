# BBB Ansible

  * [BBB Ansible](#bbb-ansible)
    * [Requirements](#requirements)
      * [Standalone BBB](#standalone-bbb)
      * [BBB Sharding](#bbb-sharding)
      * [BBB HA](#bbb-ha)
      * [Streaming](#streaming)
      * [Logging](#logging)
      * [Monitoring](#monitoring)
    * [Usage](#usage)
    * [Third-Party Documentations](#third-party-documentations)
      * [BigBlueButton](#bigbluebutton)
        * [2.2 Old Stable](#2-2-old-stable)
        * [2.3](#2-3)
        * [RTMP LiveStream](#rtmp-livestream)
          * [BigBlueButton Conferences Streaming Platform](#bigbluebutton-conferences-streaming-platform)
        * [RTSP LiveStream](#rtsp-livestream)
        * [BigBlueButton Prometheus Exporter](#bigbluebutton-prometheus-exporter)
        * [FreeSwitch Prometheus Exporter](#freeswitch-prometheus-exporter)
        * [Upgrading BigBlueButton](#upgrading-bigbluebutton)
      * [Coturn](#coturn)
      * [Scalelite](#scalelite)
      * [Greenlight](#greenlight)
      * [Moodle](#moodle)
        * [Moodle Server](#moodle-server)
        * [Moodle BigBlueButton Plugin](#moodle-bigbluebutton-plugin)
      * [Open Streaming Platform](#open-streaming-platform)
      * [PeerTube](#peertube)
      * [Misc](#misc)
    * [TODOs](#todos)
    * [FIXMEs](#fixmes)


Deploying BigBlueButton at scale with Ansible

## Requirements

 * Ansible 2.9+ on your deployment node, python-cryptography > 3, rsync
 * Ubuntu Bionic on your BigBlueButton nodes (bbb 2.3, or Xenial for bbb 2.2)
 * Debian Buster for everything else (ubuntu might work, though untested so far)

The rest depends on your context.

### Standalone BBB

 * 1 BBB instance, preferably physical, 1+ CPU, 4G+ RAM, 20G+ disk
 * (optional) 1 Greenlight instance, preferably physical, 1+ CPU, 3G+ RAM, 20G+ disk
 * (optional) 1 TURN server instance, preferably physical, 0.5+ CPU, 1G+ RAM, 20G+ disk (integrating with 3rd-party TURN possible)

### BBB Sharding

 * 2+ BBB instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * 1+ Postgres instance, could be virtual, 0.5+ CPU, 768M+ RAM, 16G disk
 * 1+ Redis instance, could be virtual, 0.5+ CPU, 1G+ RAM, 12G disk
 * 1+ Scalelite instance, preferably physical, 2+ CPU, 4G+ RAM, 30G+ disk
 * (optional) 1+ Greenlight instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * (optional) 1+ TURN server instance, preferably physical, 0.5+ CPU, 2G+ RAM, 20G+ disk

### BBB HA

 * 2+ BBB instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * 1+ Postgres instance, could be virtual, 0.5+ CPU, 768M+ RAM, 16G disk
 * 2+ Redis instance, could be virtual, 0.5+ CPU, 1G+ RAM, 12G disk
 * 2+ Scalelite instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * (optional) 2+ Greenlight instance, preferably physical, 2+ CPU, 4G+ RAM, 30G+ disk
 * (optional) 2+ TURN server instance, preferably physical, 0.5+ CPU, 2G+ RAM, 20G+ disk
 * 2+ LB instance, could be virtual, 0.5+ CPU, 1G RAM, 8G disk (in front of Redis, Scalelite, Greenlight, Prometheus, AlertManager or Grafana)
 * 1+ NFS server, SSH server (sshfs) or CephFS capable Ceph cluster, offering a shared filesystem (when more than 1 Scalelite)

### Streaming

 * 1+ RTMP server (OpenStreamingPlatform or PeerTube) instance, preferably physical, 1+ CPU, 4G+ RAM, very large disk storing records, the more resources the more concurrent streams & transcodings
 * (optional) 1+ BBB ContentStreamingPlatform instance, preferably physical/would use docker runtime, 1+ CPU, 4G+ RAM

### Logging

 * 1+ Kibana instance, could be virtual, 0.5+ CPU, 2G+ RAM, 16G disk
 * 1+ ElasticSearch instance, could be virtual, 1+ CPU, 8G+ RAM, 50G+ disk (depends on retention)

### Monitoring

 * 1+ Prometheus instance, could be virtual, 0.5+ CPU, 1G+ RAM, 50G+ disk (depends on retention, scrape interval, nodes count, ....)
 * (optional) 1+ Grafana instance, 0.5+ CPU, 768M+ RAM, 8G+ disk
 * (optional) 1+ AlertManager instance, 0.5+ CPU, 768M+ RAM, 8G+ disk

## Usage

Create your own inventory file. Several examples are provided, setting up
a standalone BBB server (`./hosts-standalone`), deploying a single instance
for most services (`./hosts-test`) or including redundancy (`./hosts-ha`).

```sh
$ cp hosts-ha hosts-my
$ ln -sf hosts-my hosts
$ vi hosts
```

Set your own deployment variables (in `./group_vars`), sensitive data could be
added to the `group_vars/private.yaml` file - start from a copy of the
`private.yaml.sample` file, adding your own secrets. We may set public service
hostnames and other global params in `group_vars/all.yaml`, then apply the
`bootstrap` playbook:

```sh
$ cp group_vars/private.yaml.sample group_vars/private.yaml
$ vi group_vars/private.yaml
$ vi group_vars/all.yaml
$ ansible-playbook -i ./hosts bootstrap.yaml
```

Dealing with distributed BBB setup, note that:

 - distributing Scalelite, the poller and recordings-importer container should
   only run once (use `scalelite_has_roles`, see `./roles/scalelite/defaults`,
   controlling which workers should run on your nodes). Alternatively, a DRBD
   volume could be shared, while pacemaker/corosync would deal with Scalelite
   containers starts/stop
 - Redis would be configured in a master/slave fashion by default, using
   sentinels: it is required to also deploy an internal loadbalancer (`lb_back`
   host group) for HAProxy to properly route client requests to your current
   master node. Alternatively, DRBD/pacemaker/corosync could be used here as
   well.
 - Postgres could also be deployed on top of a DRBD device. Which is the only
   way those playbooks currently offer to implement HA for Postgres.
 - reverses hosting the same sites would need to share LetsEncrypt account
   data, such as whichever node responds to LE challenge, it would do so with
   the same account that did initially request a certificate. During first
   deployment, only one of your reverses would pass that task. You could then
   synchronize SSL certs and virtualhosts to the other nodes and re-apply
   the bootstrap playbook.

As a general rule, drbd/pacemaker/corosync deployment is not fully automated
(initializing your drbd device, designating an initial master where you
would create and mount your filesystems, then initializing corosync cluster
and configuring resources, resource groups, ...).

A quick way to proceed would be to first deploy services on all target nodes,
without HA, ideally one hostgroup after the other. Then manually stop those
services, deal with drbd & corosync init, such as your filesystems and services
would failover to whichever drbd node is primary (samples given in
`./roles/pacemaker/setup-peertube-db.md`, `./roles/pacemaker/setup-peertube.md`,
...). Next we may edit our Ansible inventory adding the corresponding nodes to
the `drbd` host group, which would ensure Ansible would no longer try to start,
stop or enable services managed by corosync, nor create directories within
shared filesystems on drbd backup nodes.

Finally, note that using a VIP with corosync may not work everywhere, depending
on your ability to allocate your nodes with arbitrary IPs.

## Third-Party Documentations

### BigBlueButton

 * https://docs.bigbluebutton.org/dev/api.html
 * https://github.com/openfun/bbb-stress-test
 * https://www.aukfood.fr/faire-un-stress-test-sur-bigbluebutton/
 * https://docs.bigbluebutton.org/dev/recording.html
 * https://docs.bigbluebutton.org/support/faq.html

#### 2.2 Old Stable

 * https://docs.bigbluebutton.org/2.2/install.html#minimum-server-requirements
 * https://docs.bigbluebutton.org/2.2/install.html
 * https://docs.bigbluebutton.org/2.2/setup-turn-server.html
 * https://www.amazonaws.cn/en/solutions/big-blue-button-solution/
 * https://github.com/aws-samples/big-blue-button-on-aws-cn
 * https://docs.bigbluebutton.org/2.2/customize.html
 * https://github.com/createwebinar/bbb-download

#### 2.3

 * https://docs.bigbluebutton.org/dev/dev23.html
 * https://github.com/manishkatyan/bbb-mp4

#### RTMP LiveStream

 * https://github.com/aau-zid/BigBlueButton-liveStreaming
 * https://github.com/aau-zid/BigBlueButton-liveStreaming/issues/78#issuecomment-729534249
 * https://github.com/bigbluebutton/bigbluebutton/issues/8295
 * https://groups.google.com/g/bigbluebutton-dev/c/vZli5bhB1ZQ
 * https://opensource.com/article/19/1/basic-live-video-streaming-server
 * https://github.com/SeleniumHQ/selenium/wiki/Untrusted-SSL-Certificates
 * https://unix.stackexchange.com/questions/122753/chrome-certificate

##### BigBlueButton Conferences Streaming Platform

Some web UI, streaming BigBlueButton Conferences to PeerTube.

 * https://github.com/Worteks/bbb-csp

#### RTSP LiveStream

As an alternative, quick DIY, ... connect from a linux client, then run:

```sh
ffmpeg -r 30 -f x11grab -draw_mouse 0 -s ${xres}x${yres} -i :0 -c:v libvpx \
    -quality realtime -cpu-used 0 -b:v 384k -qmin 10 -qmax 42 -maxrate 384k \
    -bufsize 1000k -an screen.webm
```

And serve it using VLC, menu Media/Stream, from File, open `screen.webm`, select
output (`rtp`, `rtsp`), select a port and URL path, and start streaming.

#### BigBlueButton Prometheus Exporter

 * https://groups.google.com/g/bigbluebutton-dev/c/DcIo3hc2Vmc
 * https://bigbluebutton-exporter.greenstatic.dev/faq/
 * known bug: https://github.com/blindsidenetworks/scalelite/pull/546

#### FreeSwitch Prometheus Exporter

 * https://pypi.org/project/prometheus-freeswitch-exporter/
   probably the best option, though pip isn't installed on bbb by default
 * https://github.com/friends-of-freeswitch/mod_prometheus
   the WARNING in their readme says it all
 * https://github.com/tomponline/freeswitch_exporter
   no readme, no release, no dockerfile, 2 years since last commit. meh

#### Upgrading BigBlueButton

 * https://docs.bigbluebutton.org/2.2/install.html#upgrading-from-bigbluebutton-22
 * https://docs.bigbluebutton.org/2.2/configure-firewall.html#update-freeswitch

Behind a NAT, make sure the following are set:

 * in `/opt/freeswitch/etc/freeswitch/sip_profiles/external.xml`

```xml
<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
<param name="ext-sip-ip" value="$${external_sip_ip}"/>
```

 * in `/usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml`

```yaml
freeswitch:
  ip: <public->
  sip_ip: <private-ip>
```

 * in `/usr/share/bbb-web/WEB-INF/classes/spring/turn-stun-servers.xml`

```xml
    <bean id="turn0" class="org.bigbluebutton.web.services.turn.TurnServer">
	<constructor-arg index="0" value="<turn_secret>"/>
	<constructor-arg index="1" value="turns:<turn_fqdn>:443?transport=tcp"/>
	<constructor-arg index="2" value="86400"/>
    </bean>

    <bean id="turn1" class="org.bigbluebutton.web.services.turn.TurnServer">
	<constructor-arg index="0" value="<turn_secret>"/>
	<constructor-arg index="1" value="turn:<turn_fqdn>:443?transport=tcp"/>
	<constructor-arg index="2" value="86400"/>
    </bean>
```

### Coturn

 * https://github.com/coturn/coturn/pull/517/files
 * https://github.com/coturn/coturn/blob/master/docker/coturn/turnserver.conf
 * https://github.com/coturn/coturn/pull/627
   ^ anyway, after grabbing the sources and trying to build coturn myself,
     trying to enable that Prometheus exporter, it turns out their last release
     (4.5.1.3, June 24th) doesn't ship with that code yet. We'll have to check
     back on that later... https://coturn.net/turnserver/
 * https://ourcodeworld.com/articles/read/1175/how-to-create-and-configure-your-own-stun-turn-server-with-coturn-in-ubuntu-18-04

### Scalelite

 * https://github.com/blindsidenetworks/scalelite
 * https://blindsidenetworks.com/scaling-bigbluebutton/
 * https://medium.com/@jesusfederico_39370/scalelite-lazy-deployment-745a7be849f6
 * https://superuser.com/questions/1542421/how-to-setup-scalelite-load-balanacer-for-bigbluebutton
 * https://hub.docker.com/r/blindsidenetwks/scalelite/tags
 * https://github.com/blindsidenetworks/scalelite/blob/master/images/scalelite.png
 * https://github.com/blindsidenetworks/scalelite/blob/master/bigbluebutton/README.md
 * https://github.com/blindsidenetworks/scalelite/blob/master/sharedvolume-README.md
 * https://github.com/blindsidenetworks/scalelite/issues/147
 * https://gist.github.com/amolkhanorkar/8706915

### Greenlight

 * https://github.com/bigbluebutton/greenlight
 * https://github.com/bigbluebutton/greenlight/pull/1194
 * https://github.com/bigbluebutton/greenlight/pull/1334
 * https://github.com/bigbluebutton/greenlight/issues/1640
 * https://docs.bigbluebutton.org/greenlight/gl-admin.html#creating-accounts

### Moodle

#### Moodle Server

 * https://docs.moodle.org/39/en/Installing_Moodle#Set_up_your_server
 * https://docs.moodle.org/39/en/Installing_Moodle_on_Debian_based_distributions
 * https://docs.moodle.org/39/en/PostgreSQL
 * https://docs.moodle.org/39/en/Server_cluster
 * https://docs.moodle.org/39/en/Performance_recommendations
 * https://opensharing.fr/moodle-installation-serveur
 * https://github.com/aws-samples/moodle-on-aws-cn

#### Moodle BigBlueButton Plugin

 * https://moodle.org/plugins/mod_bigbluebuttonbn
 * https://github.com/blindsidenetworks/moodle-mod_bigbluebuttonbn

### Open Streaming Platform

 * https://openstreamingplatform.com
 * https://wiki.openstreamingplatform.com
 * https://wiki.openstreamingplatform.com/Install/Standard
 * https://wiki.openstreamingplatform.com/Usage/Streaming

### PeerTube

 * https://github.com/Chocobozzz/PeerTube
 * https://joinpeertube.org
 * https://github.com/Chocobozzz/PeerTube/tree/develop/support/docker/production

### Misc

 * https://developer.cdn.mozilla.net/fr/docs/Web/API/WebRTC_API/Connectivity
 * https://developer.cdn.mozilla.net/en-US/docs/Web/API/WebRTC_API/Connectivity
 * https://wiki.debian.org/DrBd
 * https://www.linux-dev.org/2016/03/debian-jessie-8-3-short-howto-for-corosyncpacemaker-activepassive-cluster-with-two-nodes-and-drbdlvm/
 * https://documentation.suse.com/sle-ha/12-SP4/html/SLE-HA-all/cha-ha-manual-config.html

## TODOs

 - nginx rtmp module: https://github.com/aau-zid/live-streaming-server
 - monitoring bbb services
   - soffice (tends to leave defunct processes)
 - monitoring rtmp server
 - monitoring bbb-livestream workers. beware a known limitation is that the
   livestream process doesn't reconnect, if connection to bbb is lost ...
 - monitoring openstreamingplatform
 - scaling openstreamingplatform
   - postgres not documented, look into mysql replacing the default sqlite db
   - external redis (? osp conf doesn't mention a redis DB ID, though)
   - to ensure all clients may see all RTMP streams - regardless of who serves
     a given client requests, and who receives a given stream
 - scaling bbb-csp (requires k8s/okd deployment)
 - implement cephfs storage, as an alternative to NFS/SSHFS
 - implement moodle, as an alternative to greenlight
 - greenlight/ldap integration untested
 - peertube+oidc & peertube+saml & peertube+ldap to test
 - bbb-csp+oidc & bbb-csp+saml & bbb-csp+ldap TODO
 - firewalling on hosts with docker, see
   https://www.grottedubarbu.fr/docker-firewall/
   https://github.com/firehol/firehol/issues/114
 - setup a blackbox exporter everywhere we have a webserver? Might be nice,
   at least running some basic http checks

## FIXMEs

 - redis-sentinel first fails to start
   manual restart fixed, further playbook runs work
   could be due to redis-server being slow to startup?
   or something else? pending further investigations...
 - Playbooks relying on the nginx role would first fail to start their
   nginx exporter (with no error in Ansible/playbook would still
   complete). After initial bootstrap, make sure to run the playbook
   another time...
 - Greenlight does not seem to trust our custom CA (OIDC), despite its
   being trusted on the system (?). Prefer using SAML if SSO also
   uses self-signed certificates.
 - OpenStreaming should store recordings in /var/www/videos, apparently
   using mp4 files. though I found flv files in some /tmp/systemd-private
   directory, for the nginx-osp service. Unclear what went wrong. Having run
   several short tests, I don't always find the resulting mp4 files, nor
   do I understand what's going wrong under the hood. PeerTube is more
   reliable, though quite a different product.
 - creating a BBB room with the "Automatically join me into the room"
   option selected, we sometimes end up with a 500. The room was
   properly created though. Joining back would work.
   => maybe consider adding some haproxy, with Client-IP based
      session stickiness? (any chance those 500s would be due to
      greenlight querying one scalelite creating the room, and
      another while joining in? as I'm using DNS load balancing
      right now...)
 - Scalelite poller (and arguably, the recordings importer as well) should
   only be deployed once.
 - Percona is DELETING releases of their mongodb exporter! we can't even trust
   a tagged release, ... fml. Also, they've rewrote the whole thing, as of
   0.20.x: should check how those work. Sticking to 0.11.x in the meantime
