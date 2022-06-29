# VITech

A monitoring solution for Docker hosts and containers with [Cluster-VictoriaMetrics](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html), [Prometheus](https://prometheus.io/), [Grafana](http://grafana.org/), [cAdvisor](https://github.com/google/cadvisor),
[NodeExporter](https://github.com/prometheus/node_exporter) and alerting with [AlertManager](https://github.com/prometheus/alertmanager).

Prerequisites:

* Docker Engine >= 1.13
* Docker Compose >= 1.11
* Network Load balancer for TCP ports 8480, 8481, 3000, targets to every ec2
* Configured Security Groups to allow TCP 2049, 8480, 8481, 3000, 9100, 8080, 8482, 9090, 8400, 9093, 3306.
* EC2 - 2 pieces, each with EIP(elastic ip), and RAM >= 2048mb
* EFS - 2 pieces, efs mounted to ec2 on path /mnt/efs/EFS_NAME, if you want change storage, you can edit storage path in docker-compose.yml, in vmstorage section.
```
volumes:
  - /mnt/efs/EFS_NAME:/storage
```

Containers:

* Prometheus (metrics database) `http://<host-ip>:9090`
* AlertManager (alerts management) `http://<host-ip>:9093`
* Grafana (visualize metrics) `http://<host-ip>:3000`
* NodeExporter (host metrics collector) `http://<host-ip>:9100`
* cAdvisor (containers metrics collector) `http://<host-ip>:8080`
* Cluster-VictoriaMetrics:
  - vmselect (performs incoming queries by fetching the needed data from all the configured vmstorage nodes) `http://<host-ip>:8481`
  - vmstorage (stores the raw data and returns the queried data on the given time range for the given label filters) `http://<host-ip>:8482`
  - vmisert (accepts the ingested data and spreads it among vmstorage nodes according to consistent hashing over metric name and all its labels) `http://<host-ip>:8480`

## Local deployment on Docker host ##
In this case used cluster version VictoriaMetrics, deployed on two mirror servers with network load balancer, 2 EFS, and RDS, so you need to set:
  - the mirror number
  - RDS path, user/pass, table name
  - names of EFS
  - set IP addresses from each to other
  - network load balancer dns name
  - slack webhooks and channel name for notifications

Clone this repository on your Docker host, cd into "victoria_metrics_deployment" directory edit and run "./install.sh"
```bash
git clone git@github.com:vitech-team/monitoring.git
cd monitoring/victoria_metrics_deployment
nano install.sh
```
and set variables
```
NUM_MIRROR=1 or 2
EIP_ANOTHER_MIRROR=10.10.10.10
EFS_NAME=exapmle-efs1 (or efs2)
AWS_NLB=example.us-east-1.elb.amazonaws.com (set address your aws network tcp load balancer)
RDS_HOST=example.us-east-1.rds.amazonaws.com (set address database for grafana)
RDS_USER=user (set database user)
RDS_PASS=pass (set database password)
RDS_TABLE_NAME=grafana (set database name)
SLACK_ALERT_HOOK=slack hookies
SLACK_ALERT_CHANNEL=slack channel
```
EXAMPLE:
First ec2 ip=10.10.10.1, second ec2 ip=10.10.10.2
```
example for first mirror
NUM_MIRROR=1
EIP_ANOTHER_MIRROR=10.10.10.2
EFS_NAME=efs1
........

example for second mirror
NUM_MIRROR=2
EIP_ANOTHER_MIRROR=10.10.10.1
EFS_NAME=efs2
........
```

Run ./install.sh , that will automatically install docker and docker-compose, set data in prometheus.yml, grafana datasource.yml and config.ini, docker-compose.yml, alertmanager.yml, alertrules.yml, and starts all containers.


## Setup Grafana

Navigate to `http://AWS-NLB:3000` and login with user ***admin*** password ***admin***, and change password


Grafana is preconfigured with dashboards and VictoriaMetrics as the default data source:

* Name: VictoriaMetrics
* Type: prometheus
* Url: [http://AWS-NLB:8481/select/0/prometheus](http://AWS-NLB:8481/select/0/prometheus)
* Access: proxy

## Automated Terraform deployment ##

......................instruction soon will be heer.....ASAP..................maybe before new year (2023).....

## Define alerts

Three alert groups have been setup within the [alertrules.yml](https://github.com/vitech-team/monitoring/blob/main/victoria_metrics_deployment/prometheus/alertrules.yml) configuration file:

* Monitoring services alerts [targets](https://github.com/vitech-team/monitoring/blob/main/victoria_metrics_deployment/prometheus/alertrules.yml#L2-L11)
* Docker Host alerts [host](https://github.com/vitech-team/monitoring/blob/main/victoria_metrics_deployment/prometheus/alertrules.yml#L13-L40)
* Docker Containers alerts [containers](https://github.com/vitech-team/monitoring/blob/main/victoria_metrics_deployment/prometheus/alertrules.yml#L42-L239)

***Monitoring services alerts***

Trigger an alert if any of the monitoring targets (node-exporter and cAdvisor) are down for more than 30 seconds:

```yaml
- alert: monitor_service_down
    expr: up == 0
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: "Monitor service non-operational"
      description: "Service {{ $labels.instance }} is down."
```

***Docker Host alerts***

Trigger an alert if the Docker host CPU is under high load for more than 30 seconds:

```yaml
- alert: high_cpu_load
    expr: node_load1 > 2.5
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: "Server under high load"
      description: "Docker host is under high load, the avg load 1m is at {{ $value}}. Reported by instance {{ $labels.instance }} of job {{ $labels.job }}."
```

Modify the load threshold based on your CPU cores.

Trigger an alert if the Docker host memory is almost full:

```yaml
- alert: high_memory_load
    expr: (sum(node_memory_MemTotal_bytes) - sum(node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) ) / sum(node_memory_MemTotal_bytes) * 100 > 85
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: "Server memory is almost full"
      description: "Docker host memory usage is {{ humanize $value}}%. Reported by instance {{ $labels.instance }} of job {{ $labels.job }}."
```

Trigger an alert if the Docker host storage is almost full:

```yaml
- alert: high_storage_load
    expr: (node_filesystem_size_bytes{fstype="xfs"} - node_filesystem_free_bytes{fstype="xfs"}) / node_filesystem_size_bytes{fstype="xfs"}  * 100 > 85
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: "Server storage is almost full"
      description: "Docker host storage usage is {{ humanize $value}}%. Reported by instance {{ $labels.instance }} of job {{ $labels.job }}."
```

***Docker Containers alerts***

Trigger an alert if a container is down for more than 30 seconds:
[container_name] = nodeexporter or another container name, without any qouatas

```yaml
- alert: [container_name]_down
    expr: absent(container_memory_usage_bytes{name="[container_name]"})
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: "[container_name] down"
      description: "[container_name] container is down for more than 30 seconds."
```

Trigger an alert if a container is using more than 10% of total CPU cores for more than 30 seconds:

```yaml
- alert: [container_name]_high_cpu
    expr: sum(rate(container_cpu_usage_seconds_total{name="[container_name]"}[1m])) / count(node_cpu_seconds_total{mode="system"}) * 100 > 10
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: "[container_name] high CPU usage"
      description: "[container_name] CPU usage is {{ humanize $value}}%."
```

Trigger an alert if a container is using more than 1.2GB of RAM for more than 30 seconds:

```yaml
- alert: [container_name]_high_memory
    expr: sum(container_memory_usage_bytes{name="[container_name]"}) > 1200000000
    for: 30s
    labels:
      severity: warning
    annotations:
      summary: "[container_name] high memory usage"
      description: "[container_name] memory consumption is at {{ humanize $value}}."
```

## Setup alerting

The AlertManager service is responsible for handling alerts sent by Prometheus server.
AlertManager can send notifications via email, Pushover, Slack, HipChat or any other system that exposes a webhook interface.
A complete list of integrations can be found [here](https://prometheus.io/docs/alerting/configuration).

You can view and silence notifications by accessing `http://<host-ip>:9093`.

The notification receivers can be configured in [alertmanager/config.yml](https://github.com/vitech-team/monitoring/blob/main/victoria_metrics_deployment/alertmanager.yml) file.

To receive alerts via Slack you need to make a custom integration by choose ***incoming web hooks*** in your Slack team app page.
You can find more details on setting up Slack integration [here](http://www.robustperception.io/using-slack-with-the-alertmanager/).

Copy the Slack Webhook URL into the ***api_url*** field and specify a Slack ***channel***.

```yaml
..........
receivers:
- name: 'slack'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/<webhook-id>'
    username: 'Alertmanager'
    channel: '#<channel-name>'
    send_resolved: true
    title: |-
.......
```
