#!/bin/bash
set -e  # Exit on error

# Update system
apt-get update && apt-get upgrade -y

# Install Python 3.11
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install python3.11 python3.11-venv python3-pip -y

# Install PostgreSQL client
apt-get install postgresql-client -y

# Install SSM Agent
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create app directory
mkdir -p /opt/linguallearn-api
chown ubuntu:ubuntu /opt/linguallearn-api

# Log completion
echo "User data script completed at $(date)" > /var/log/user-data-complete.log
