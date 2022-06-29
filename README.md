# VITech

A monitoring solution for Docker hosts and containers with [Prometheus](https://prometheus.io/), [Grafana](http://grafana.org/), [cAdvisor](https://github.com/google/cadvisor),
[NodeExporter](https://github.com/prometheus/node_exporter) and alerting with [AlertManager](https://github.com/prometheus/alertmanager).

Prerequisites:

* Docker Engine >= 1.13
* Docker Compose >= 1.11

Containers:

* Prometheus (metrics database) `http://<host-ip>:9090`
* Prometheus-Pushgateway (push acceptor for ephemeral and batch jobs) `http://<host-ip>:9091`
* AlertManager (alerts management) `http://<host-ip>:9093`
* Grafana (visualize metrics) `http://<host-ip>:3000`
* NodeExporter (host metrics collector) `http://<host-ip>:9100`
* cAdvisor (containers metrics collector) `http://<host-ip>:8080`

## Local deployment on Docker host ##

Clone this repository on your Docker host, cd into "local_deployment" directory and run "docker-compose up -d", by default username and password for Grafana admin/admin, You can change the credentials in the compose file or by supplying the `ADMIN_USER` and `ADMIN_PASSWORD` environment variables on compose up:

```bash
git clone https://github.com/vitech-team/monitoring/local_deployment
cd local_deployment
./install.sh
ADMIN_USER=admin ADMIN_PASSWORD=admin docker-compose up -d
```
## Setup Grafana

Navigate to `http://<host-ip>:3000` and login with user ***admin*** password ***admin***.

If you want to change the password  after run docker-compose up -d, you have to remove this entry, otherwise the change will not take effect

```yaml
- grafana_data:/var/lib/grafana
```

Grafana is preconfigured with dashboards and Prometheus as the default data source:

* Name: Prometheus
* Type: Prometheus
* Url: [http://prometheus:9090](http://prometheus:9090)
* Access: proxy

## Automated Terraform deployment ##

......................instruction soon will be heer.....ASAP..................maybe before new year.....

## Define alerts

Three alert groups have been setup within the [alert.rules](https://github.com/vitech-team/monitoring/blob/main/local_deployment/prometheus/alert.rules) configuration file:

* Monitoring services alerts [targets](https://github.com/vitech-team/monitoring/blob/main/local_deployment/prometheus/alert.rules#L2-L11)
* Docker Host alerts [host](https://github.com/vitech-team/monitoring/blob/main/local_deployment/prometheus/alert.rules#L13-L40)
* Docker Containers alerts [containers](https://github.com/vitech-team/monitoring/blob/main/local_deployment/prometheus/alert.rules#L42-L97)

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
    expr: node_load1 > 1.5
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

The notification receivers can be configured in [alertmanager/config.yml](https://github.com/vitech-team/monitoring/blob/main/local_deployment/alertmanager/config.yml) file.

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

## Sending metrics to the Pushgateway

The [pushgateway](https://github.com/prometheus/pushgateway) is used to collect data from batch jobs or from services.

To push data, simply execute:

```bash
echo "some_metric 3.14" | curl --data-binary @- http://user:password@localhost:9091/metrics/job/some_job
```

Replace the `user:password` part with your user and password set in the initial configuration (default: `admin:admin`).
