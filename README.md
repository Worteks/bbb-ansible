# BBB Ansible

  * [BBB Ansible](#bbb-ansible)
    * [Requirements](#requirements)
      * [Standalone BBB](#standalone-bbb)
      * [BBB Sharding](#bbb-sharding)
      * [BBB HA](#bbb-ha)
      * [Monitoring](#monitoring)
    * [Usage](#usage)
    * [Third-Party Documentations](#third-party-documentations)
      * [BigBlueButton](#bigbluebutton)
        * [2.2](#2-2)
        * [2.3-dev](#2-3-dev)
        * [API](#api)
        * [RTMP LiveStream](#rtmp-livestream)
        * [RTSP LiveStream](#rtsp-livestream)
        * [BigBlueButton Prometheus Exporter](#bigbluebutton-prometheus-exporter)
        * [FreeSwitch Prometheus Exporter](#freeswitch-prometheus-exporter)
        * [Upgrading BigBlueButton](#upgrading-bigbluebutton)
      * [Coturn](#coturn)
      * [Scalelite](#scalelite)
      * [Geenlight](#greenlight)
      * [Moodle](#moodle)
        * [Moodle Server](#moodle-server)
        * [Moodle BigBlueButton Plugin](#moodle-bigbluebutton-plugin)
    * [TODOs](#todos)
    * [FIXMEs](#fixmes)


Deploying BigBlueButton at scale with Ansible

## Requirements

 * Ansible 2.9+ on your deployment node
 * Ubuntu Xenial on your BigBlueButton nodes (bbb 2.2, or Bionic for bbb 2.3-dev)
 * Debian Buster for everything else (ubuntu might work, though untested so far)

The rest depends on your context.

Note: this is still a work in progress. Feel free to file an issue on GitHub, if
there's anything you need help fixing.

### Standalone BBB

 * 1 BBB instance, preferably physical, 1+ CPU, 4G+ RAM, 20G+ disk
 * (optional) 1 Greenlight instance, preferably physical, 1+ CPU, 3G+ RAM, 20G+ disk
 * (optional) 1 TURN instance, preferably physical, 0.5+ CPU, 1G+ RAM, 20G+ disk (integrating with 3rd-party TURN possible)
 * (optional) 1+ RTMP instance, preferably physical, 0.5+ CPU, 2G+ RAM, 8G+ disk

### BBB Sharding

 * 2+ BBB instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * 1+ Postgres instance, could be virtual, 0.5+ CPU, 768M+ RAM, 16G disk
 * 1+ Redis instance, could be virtual, 0.5+ CPU, 1G+ RAM, 12G disk
 * 1+ Scalelite instance, preferably physical, 2+ CPU, 4G+ RAM, 30G+ disk
 * (optional) 1+ Greenlight instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * (optional) 1+ TURN instance, preferably physical, 0.5+ CPU, 2G+ RAM, 20G+ disk
 * (optional) 1+ RTMP instance, preferably physical, 0.5+ CPU, 2G+ RAM, 8G+ disk

### BBB HA

 * 2+ BBB instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * 1+ Postgres instance, could be virtual, 0.5+ CPU, 768M+ RAM, 16G disk
 * 2+ Redis instance, could be virtual, 0.5+ CPU, 1G+ RAM, 12G disk
 * 2+ Scalelite instance, preferably physical, 4+ CPU, 8G+ RAM, 50G+ disk
 * (optional) 2+ Greenlight instance, preferably physical, 2+ CPU, 4G+ RAM, 30G+ disk
 * (optional) 2+ TURN instance, preferably physical, 0.5+ CPU, 2G+ RAM, 20G+ disk
 * (optional) 1+ RTMP instance, preferably physical, 0.5+ CPU, 2G+ RAM, 8G+ disk
 * 2+ LB instance, could be virtual, 0.5+ CPU, 1G RAM, 8G disk (in front of Redis, Scalelite, Greenlight, Prometheus, AlertManager or Grafana)
 * 1+ NFS server, SSH server (sshfs) or CephFS capable Ceph cluster, offering a shared filesystem (when more than 1 Scalelite)

### Monitoring

 * 1+ Prometheus instance, could be virtual, 0.5+ CPU, 1G+ RAM, 50G+ disk (depends on retention, scrape interval, nodes count, ....)
 * (optional) 1+ Grafana instance, 0.5+ CPU, 768M+ RAM, 8G+ disk
 * (optional) 1+ AlertManager instance, 0.5+ CPU, 768M+ RAM, 8G+ disk

## Usage

Edit inventory file (`./hosts`) and deployment variables (in `./group_vars`),
then bootstrap your setup using Ansible:

```
$ ansible-playbook -i ./hosts bootstrap.yaml
```

Deploying a distributed BBB setup, with single Scalelite & single Greenlight
works. On the other hand:

 - distributing Scalelite should be possible though bear in mind its spool
   directory being shared, a same recording might be processed multiple times
   (in theory / to check / did not see anything like this so far). On the other
   hand, we could make it such as the record-processing worker only works on one
   node - playbooks would allow for this, though it has not been tested yet. Or
   just mount the published folder on sshfs, and keep local spools
 - Moodle is in my TODO, as an optional replacement for Greenlight
 - Postgres refactor as well (something HA-capable?).

## Third-Party Documentations

### BigBlueButton

#### 2.2

 * https://docs.bigbluebutton.org/legacy/11install.html#check-server-specs
 * https://docs.bigbluebutton.org/2.2/install.html
 * https://docs.bigbluebutton.org/2.2/setup-turn-server.html
 * https://www.amazonaws.cn/en/solutions/big-blue-button-solution/
 * https://github.com/aws-samples/big-blue-button-on-aws-cn

#### 2.3-dev

 * https://github.com/bigbluebutton/bbb-install/issues/37
 * https://docs.bigbluebutton.org/dev/dev23.html

#### API

 * https://docs.bigbluebutton.org/dev/api.html

#### RTMP LiveStream

 * https://github.com/aau-zid/BigBlueButton-liveStreaming
 * https://github.com/bigbluebutton/bigbluebutton/issues/8295
 * https://groups.google.com/g/bigbluebutton-dev/c/vZli5bhB1ZQ
 * https://opensource.com/article/19/1/basic-live-video-streaming-server

#### RTSP LiveStream

As an alternative, quick DIY, ... connect from a linux client, then run:

```
ffmpeg -r 30 -f x11grab -draw_mouse 0 -s ${xres}x${yres} -i :0 -c:v libvpx \
    -quality realtime -cpu-used 0 -b:v 384k -qmin 10 -qmax 42 -maxrate 384k \
    -bufsize 1000k -an screen.webm
```

And serve it using VLC, menu Media/Stream, from File, open `screen.webm`, select
output (`rtp`, `rtsp`), select a port and URL path, and start streaming.

#### BigBlueButton Prometheus Exporter

 * https://groups.google.com/g/bigbluebutton-dev/c/DcIo3hc2Vmc
 * https://bigbluebutton-exporter.greenstatic.dev/faq/

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

 * in `/usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml`

```
<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
<param name="ext-sip-ip" value="$${external_sip_ip}"/>
```

 * in `/opt/freeswitch/etc/freeswitch/sip_profiles/external.xml`

```
freeswitch:
  ip: <public->
  sip_ip: <private-ip>
```

 * in `/usr/share/bbb-web/WEB-INF/classes/spring/turn-stun-servers.xml`

```
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

## TODOs

 - monitoring bbb services
   - etherpad
     (patch needed @ https://gitlab.com/synacksynack/opsperator/s2i-etherpad)
     (also broken dependency / PR accepted, should make sure it was pushed)
   - kurento-media-server
     => https://github.com/mariogasparoni/kurento-monitor
   - bbb-web (?)
   - soffice
 - monitoring scalelite poller (count items in spool?)
 - monitoring turn
 - monitoring rtmp server
 - monitoring bbb-livestream workers. beware a known limitation is that the
   livestream process doesn't reconnect, if connection to bbb is lost ...
 - WIP NFS storage
   => sharing the spool directory might lead multiple Scalelite replicas
      processing a same recording (?)
 - WIP BBB recordings
   => bbb would currently push recordings to the "first" scalelite node
      (following the order of your nodes, as defined in Ansible inventory),
      which is not HA-friendly. Either patch the bbb post-publish script
      iterating over several scalelite nodes, if necessary. Or consider using
      Scalelite shared FQDN (`scalelite_fqdn`) as rsync target (and either
      disable host keys verification, or have Ansible make sure SSH host
      keys would be shared on all Scalelite nodes, ... yikes...)
 - implement cephfs storage, as an alternative to NFS/SSHFS
 - implement moodle, as an alternative to greenlight
 - greenlight/ldap integration untested
 - firewalling on hosts with docker-compose
 - setup a blackbox exporter everywhere we have a webserver? Might be nice,
   at least to check for certificates expiry dates, and some basic http check
 - nginx metrics from https://github.com/knyar/nginx-lua-prometheus
   -- currently, nginx prometheus rules pretty much all refer to those metrics

## FIXMEs

 - redis-sentinel first fails to start
   manual restart fixed, further playbook runs work
   could be due to redis-server being slow to startup?
   or something else? pending further investigations...
 - bbb-install first fails to complete
   to be fair, problem did occure after my SSH session was closed
   (inactivity timeout), apt was still running on the bbb hosts,
   until it didn't, ... might not be reproducible under normal
   circumstances / in a screen or tmux
 - Playbooks relying on the nginx role would first fail to start their
   nginx exporter (with no error in Ansible/playbook would still
   complete). After initial bootstrap, make sure to run the playbook
   another time...
 - Greenlight does not seem to trust our custom CA (OIDC), despite its
   being trusted on the system (?)
 - Starting up BBB LiveStream, systemd unit first
   appears to fail starting our container, while further check would
   confirm it was/is properly running
 - creating a BBB room with the "Automatically join me into the room"
   option selected, we sometimes end up with a 500. The room was
   properly created though. Joining back would work.
   => maybe consider adding some haproxy, with Client-IP based
      session stickiness? (any chance those 500s would be due to
      greenlight querying one scalelite creating the room, and
      another while joining in? as I'm using DNS load balancing
      right now...)
