# Kibana

## Geo Points

Having deployed Kibana & Fluentd/td-agent, and configured some URL downloading
a GeoIP City database, we would have to cast some key into a `geo_point`, for
Kibana to allow its usage in maps visualizations.

To do so, go to the Kibana Management panel, then to Data / Index Management,
in the Index Template tab, create a new Index Template.

First screen: give your template a name. As index pattern, use `logstash-*`,
no need to enable Data Stream, nor for a Priority. Set the version to 1. No
`_meta` field.

Second screen, component templates: don't pick anything. Third screen, index
settings, leave it empty.

Fourth screen, mappings: add a mapping, for the field `location_string`, and
set its Field Type to `geo_point`.

Fifth screen, aliases: leave it empty. Last screen: review template, confirm
we're just casting our key to geo_point, and submit.

If Fluentd started submitting logs, we would have to wait another day, for a
new index to create, and load our custom template. As an alternative, we could
stop all fluentds, delete todays index from ElasticSearch and re-start fluentds.

## Saved Searches

A few searches we could save into Kibana, once deployed:

|                    | Search Filter                                           |
| -----------------: | :------------------------------------------------------ |
| BigBlueButton Apps | `@log_name:bigbluebutton*`                              |
| BigBlueButton Web  | `hostname:bbb* AND @log_name:nginx.access`              |
| Coturn             | `systemd_unit:coturn.service`                           |
| CSP App            | `systemd_unit:bbbcsp.service`                           |
| CSP Web            | `hostname:csp* AND @log_name:nginx.access`              |
| ElasticSearch DB   | `systemd_unit:elasticsearch.service`                    |
| FreeSwitch         | `@log_name:bigbluebutton.freeswitch`                    |
| Grafana App        | `systemd_unit:grafana.service`                          |
| Grafana Web        | `hostname:grafana* AND @log_name:nginx.access`          |
| Greenlight App     | `systemd_unit:greenlight.service`                       |
| Greenlight Web     | `hostname:greenlight* AND @log_name:nginx.access`       |
| Kibana App         | `systemd_unit:kibana.service`                           |
| Kibana Web         | `hostname:kibana* AND @log_name:nginx.access`           |
| MongoDB DB         | `@log_name:database.mongodb`                            |
| PeerTube App       | `systemd_unit:peertube.service`                         |
| PeerTube Web       | `hostname:peertube* AND @log_name:nginx.access`         |
| Reverse Web        | `hostname:reverse* AND @log_name:nginx.access`          |
| Postgres DB        | `@log_name:database.postgres`                           |
| Redis DB           | `@log_name:database.redis`                              |
| SSH Logs           | `systemd_unit:ssh.service OR systemd_unit:sshd.service` |
| Prometheus App     | `systemd_unit:prometheus.service`                       |
| Prometheus Web     | `hostname:prometheus* AND @log_name:nginx.access`       |
| Scalelite App      | `systemd_unit:scalelite.service`                        |
| Scalelite Web      | `hostname:scalelite* AND @log_name:nginx.access`        |
| Web Accesses       | `@log_name:nginx.access`                                |
