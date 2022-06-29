#!/bin/bash
DOCKER_COMPOSE_VERSION="1.29.2"
DOCKER_DAEMON=/etc/docker/daemon.json
DOCKER_COMPOSE_FILE=/usr/local/bin/docker-compose

# Check for first run install.sh
OS=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)
CHECK_FILE=/etc/monitoring/output_install.txt
if [ -f "$CHECK_FILE" ]; then
    echo "$CHECK_FILE exists."
exit 1

# Check docker install
fi
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

# Enable docker daemon
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

# Check docker-compose install
fi
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "docker-compose exists."
  else
  echo "docker-compose does not exist."
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo systemctl restart docker

# Make check-file for install.sh first run
sudo touch "$CHECK_FILE"
sudo chmod 666 "$CHECK_FILE"
sudo cat <<\EOT >> "$CHECK_FILE"
    {
      this is check_file for install.sh
    }
EOT
fi

# Run docker-compose
docker-compose --project-directory /etc/monitoring --file /etc/monitoring/docker-compose.yml up -d
