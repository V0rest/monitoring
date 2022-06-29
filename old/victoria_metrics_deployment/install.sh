#!/bin/bash
###################set mirrors environment variables###########################
NUM_MIRROR=
EIP_ANOTHER_MIRROR=
EFS_NAME=
AWS_NLB=
RDS_HOST=
RDS_USER=
RDS_PASS=
RDS_TABLE_NAME=
SLACK_ALERT_HOOK=
SLACK_ALERT_CHANNEL=
################################################################################
DOCKER_COMPOSE_VERSION="1.29.2"
DOCKER_DAEMON=/etc/docker/daemon.json
DOCKER_COMPOSE_FILE=/usr/local/bin/docker-compose
OS=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)

sudo sed -i -e "s|SLACK_ALERT_HOOK|$SLACK_ALERT_HOOK|" ./alertmanager.yml
sudo sed -i -e "s|SLACK_ALERT_CHANNEL|$SLACK_ALERT_CHANNEL|" ./alertmanager.yml
sudo sed -i -e "s|AWS_NLB|$AWS_NLB|" ./docker-compose.yml
sudo sed -i -e "s|NUM_MIRROR|$NUM_MIRROR|" ./docker-compose.yml
sudo sed -i -e "s|EIP_ANOTHER_MIRROR|$EIP_ANOTHER_MIRROR|" ./docker-compose.yml
sudo sed -i -e "s|NUM_MIRROR|$NUM_MIRROR|" ./prometheus/alertrules.yml
sudo sed -i -e "s|NUM_MIRROR|$NUM_MIRROR|" ./prometheus/prometheus.yml
sudo sed -i -e "s|EIP_ANOTHER_MIRROR|$EIP_ANOTHER_MIRROR|" ./prometheus/alertrules.yml
sudo sed -i -e "s|EIP_ANOTHER_MIRROR|$EIP_ANOTHER_MIRROR|" ./prometheus/prometheus.yml
sudo sed -i -e "s|AWS_NLB|$AWS_NLB|" ./prometheus/prometheus.yml
sudo sed -i -e "s|AWS_NLB|$AWS_NLB|" ./grafana/provisioning/datasources/datasource.yml
sudo sed -i -e "s|RDS_HOST|$RDS_HOST|" ./grafana/config.ini
sudo sed -i -e "s|RDS_USER|$RDS_USER|" ./grafana/config.ini
sudo sed -i -e "s|RDS_PASS|$RDS_PASS|" ./grafana/config.ini
sudo sed -i -e "s|RDS_TABLE_NAME|$RDS_TABLE_NAME|" ./grafana/config.ini

##########Check docker install##################################################
if [[ $(docker -v) != *"version"* ]] && [ "$OS" != '"amzn"' ]; then
  echo "docker not installed on debian-like distro"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
elif [[ $(docker -v) != *"version"* ]] && [ "$OS" = '"amzn"' ]; then
  echo "docker not installed on amazon linux"
sudo amazon-linux-extras install docker -y
else
  echo "docker already installed"
fi
if [ -f "$DOCKER_DAEMON" ]; then
    echo "$DOCKER_DAEMON exist."
else
    echo "$DOCKER_DAEMON does not exist."

###### enable docker daemon#####################################################
sudo touch "$DOCKER_DAEMON"
sudo chmod 666 "$DOCKER_DAEMON"
sudo cat <<\EOT >> "$DOCKER_DAEMON"
    {
      "metrics-addr" : "0.0.0.0:9323",
      "experimental" : true
    }
EOT
sudo usermod -a -G docker $(whoami)
sudo systemctl restart docker
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart docker

###########Check docker-compose install#########################################
fi
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "docker-compose exists."
  else
  echo "docker-compose does not exist."
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo systemctl restart docker
fi
# Run docker-compose
docker-compose up -d
