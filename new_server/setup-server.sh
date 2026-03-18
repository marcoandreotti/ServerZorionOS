#!/usr/bin/env bash
set -e

echo "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "Instalando utilitários..."
sudo apt install -y \
curl wget git unzip ufw net-tools \
apt-transport-https ca-certificates gnupg \
software-properties-common

echo "Instalando Nginx..."
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "Instalando PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "Instalando Redis..."
sudo apt install -y redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server

echo "Instalando Samba..."
sudo apt install -y samba
sudo systemctl enable smbd
sudo systemctl start smbd

echo "Instalando Docker..."

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update

sudo apt install -y \
docker-ce docker-ce-cli containerd.io \
docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

echo "Instalando .NET Runtime..."

wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb \
-O packages-microsoft-prod.deb

sudo dpkg -i packages-microsoft-prod.deb
sudo apt update

sudo apt install -y aspnetcore-runtime-9.0 dotnet-runtime-9.0

echo "Criando estrutura de pastas..."

sudo mkdir -p /opt/apps/XControlFin/publish
sudo mkdir -p /opt/apps/scripts
sudo mkdir -p /opt/apps/backups

sudo mkdir -p /srv/samba/public
sudo mkdir -p /srv/samba/private

sudo chmod -R 775 /opt/apps
sudo chmod -R 777 /srv/samba/public
sudo chmod -R 770 /srv/samba/private

echo "Configurando firewall..."

sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5000/tcp
sudo ufw allow 5678/tcp
sudo ufw allow 139/tcp
sudo ufw allow 445/tcp

sudo ufw --force enable

echo "Servidor configurado com sucesso!"