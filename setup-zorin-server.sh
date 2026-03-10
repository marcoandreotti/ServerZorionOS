#!/bin/bash

set -e

echo "============================================="
echo " ZORIN SERVER SETUP"
echo " PostgreSQL + Samba + .NET API + Nginx"
echo "============================================="

# -----------------------------
# CONFIGURAÇÕES
# -----------------------------

PG_USER="apiuser"
PG_DB="apidb"
PG_PASSWORD="SenhaForte123"

SAMBA_SHARE="/srv/shared"

APP_NAME="MinhaApi"
APP_PATH="/opt/apps/$APP_NAME"

SUBNET="192.168.0.0/24"

# -----------------------------
# ATUALIZAR SISTEMA
# -----------------------------

echo "Atualizando sistema..."

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
curl \
wget \
git \
unzip \
build-essential \
ufw

# -----------------------------
# INSTALAR POSTGRESQL
# -----------------------------

echo "Instalando PostgreSQL..."

sudo apt install -y postgresql postgresql-contrib

sudo systemctl enable postgresql
sudo systemctl start postgresql

# -----------------------------
# CONFIGURAR POSTGRESQL
# -----------------------------

echo "Configurando PostgreSQL..."

sudo -u postgres psql <<EOF
CREATE USER $PG_USER WITH PASSWORD '$PG_PASSWORD';
CREATE DATABASE $PG_DB OWNER $PG_USER;
GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_USER;
EOF

PG_CONF=$(find /etc/postgresql -name postgresql.conf)
PG_HBA=$(find /etc/postgresql -name pg_hba.conf)

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

echo "host all all $SUBNET md5" | sudo tee -a $PG_HBA

sudo systemctl restart postgresql

# -----------------------------
# FIREWALL
# -----------------------------

echo "Configurando firewall..."

sudo ufw allow 22/tcp
sudo ufw allow 5432/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 445/tcp
sudo ufw allow 139/tcp

sudo ufw --force enable

# -----------------------------
# INSTALAR SAMBA
# -----------------------------

echo "Instalando Samba..."

sudo apt install -y samba

sudo mkdir -p $SAMBA_SHARE
sudo chmod 777 $SAMBA_SHARE

sudo bash -c "cat >> /etc/samba/smb.conf" <<EOL

[Shared]
   path = $SAMBA_SHARE
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
EOL

sudo systemctl restart smbd

# -----------------------------
# INSTALAR .NET
# -----------------------------

echo "Instalando .NET SDK..."

wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

sudo dpkg -i packages-microsoft-prod.deb

sudo apt update

sudo apt install -y dotnet-sdk-10.0

dotnet --version

# -----------------------------
# CRIAR API
# -----------------------------

echo "Criando API..."

sudo mkdir -p /opt/apps

cd /opt/apps

sudo dotnet new webapi -n $APP_NAME

cd $APP_NAME

sudo dotnet publish -c Release -o $APP_PATH

# -----------------------------
# SYSTEMD SERVICE
# -----------------------------

echo "Criando serviço systemd..."

sudo bash -c "cat > /etc/systemd/system/$APP_NAME.service" <<EOL
[Unit]
Description=$APP_NAME API
After=network.target

[Service]
WorkingDirectory=$APP_PATH
ExecStart=/usr/bin/dotnet $APP_PATH/$APP_NAME.dll
Restart=always
RestartSec=10
SyslogIdentifier=$APP_NAME
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload

sudo systemctl enable $APP_NAME
sudo systemctl start $APP_NAME

# -----------------------------
# INSTALAR NGINX
# -----------------------------

echo "Instalando Nginx..."

sudo apt install -y nginx

sudo bash -c "cat > /etc/nginx/sites-available/$APP_NAME" <<EOL
server {
    listen 80;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/

sudo nginx -t

sudo systemctl restart nginx

# -----------------------------
# FINAL
# -----------------------------

echo ""
echo "============================================="
echo " INSTALAÇÃO CONCLUÍDA"
echo "============================================="

echo "PostgreSQL:"
echo "Host: IP_DO_SERVIDOR"
echo "Database: $PG_DB"
echo "User: $PG_USER"
echo "Password: $PG_PASSWORD"

echo ""
echo "Samba:"
echo "Compartilhamento: $SAMBA_SHARE"

echo ""
echo "API:"
echo "http://IP_DO_SERVIDOR"