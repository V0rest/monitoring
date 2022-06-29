#!/bin/bash
OS=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)
if [ "$OS" != '"amzn"' ]; then
wget https://s3.amazonaws.com/amazon-ssm-region/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl --enable amazon-ssm-agent
fi
