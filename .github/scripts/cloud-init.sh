#!/bin/sh

set -eux
trap 'poweroff' TERM EXIT INT

Repo=$(curl http://169.254.169.254/latest/meta-data/tags/instance/Repo)
Branch=$(curl http://169.254.169.254/latest/meta-data/tags/instance/Branch)

Local_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Install pkgs
apt-get update
apt-get install -y net-tools
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker ubuntu

su -P ubuntu -c "git clone -b $Branch --single-branch https://github.com/ntampakas/$Repo.git /home/ubuntu/$Repo"
su -P ubuntu -c "sed -i \"s/http:\/\/127.0.0.1:8000/http:\/\/$Local_IP:8000/g\" /home/ubuntu/$Repo/packages/frontend/src/config.ts"
su -P ubuntu -c "sed -i \"s/node-ip/$Local_IP/\" /home/ubuntu/$Repo/compose.yaml"
su -P ubuntu -c "cd /home/ubuntu/$Repo ; docker compose up -d"

sleep 12h
