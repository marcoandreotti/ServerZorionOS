# <span style="color:purple; font-weight:bold">Zorin OS Server Setup</span>
<span style="color:red;">PostgreSQL + Samba + .NET API</span>


# Como usar: setup-zorin-server.sh
Dar permissão:
```txt
chmod +x setup-zorin-server.sh
```
Executar:
```txt
sudo ./setup-zorin-server.sh
```
## Resultado

### Seu notebook vira um mini servidor com:
* PostgreSQL acessível na rede
* Samba para compartilhamento
* API ASP.NET rodando como serviço
* Nginx publicando API
* Firewall configurado

---
---
---



# Como fazer manualmente:
Este guia transforma um notebook com Zorin OS / Ubuntu-based em um pequeno servidor doméstico ou de laboratório contendo:

🐘 PostgreSQL com acesso remoto

📂 Compartilhamento de arquivos via Samba

⚙️ Runtime e SDK .NET 10

🌐 Publicação de API ASP.NET Core

🔁 Serviço rodando automaticamente via systemd

(Opcional) Proxy reverso com Nginx

### 1 — Atualizar o sistema
```txt
sudo apt update
sudo apt upgrade -y
```
Instalar ferramentas básicas:
```txt
sudo apt install -y curl wget git unzip build-essential
```

### 2 — Instalar PostgreSQL
```txt
sudo apt install -y postgresql postgresql-contrib
```

Verificar serviço:
```txt
sudo systemctl status postgresql
```
Habilitar no boot:
```txt
sudo systemctl enable postgresql
```
### 3 — Criar usuário e banco

Entrar no shell do postgres:
```txt
sudo -u postgres psql
```
Criar usuário:
```txt
CREATE USER apiuser WITH PASSWORD 'SenhaForte123';
```
Criar banco:
```txt
CREATE DATABASE apidb OWNER apiuser;
```
Permitir privilégios:
```txt
GRANT ALL PRIVILEGES ON DATABASE apidb TO apiuser;
```
Sair:
```txt
\q
```

### 4 — Permitir acesso remoto ao PostgreSQL

Editar configuração:
```txt
sudo nano /etc/postgresql/*/main/postgresql.conf
```
Localizar:
```txt
#listen_addresses = 'localhost'
```
Alterar para:
```txt
listen_addresses = '*'
```
Editar regras de acesso:
```txt
sudo nano /etc/postgresql/*/main/pg_hba.conf
```
Adicionar no final:
```txt
host all all 192.168.0.0/24 md5
```
Reiniciar PostgreSQL:
```txt
sudo systemctl restart postgresql
```
Agora outro computador da rede poderá conectar:
```txt
Host: IP_DO_SERVIDOR
Port: 5432
User: apiuser
Password: SenhaForte123
```

5 — Abrir firewall

Se estiver usando UFW:
```txt
sudo ufw allow 5432/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 445/tcp
sudo ufw allow 139/tcp
sudo ufw enable
```

### 6 — Instalar Samba (compartilhamento de arquivos)

Instalar:
```txt
sudo apt install -y samba
```
Criar pasta compartilhada:
```txt
sudo mkdir -p /srv/shared
```
Permissões:
```txt
sudo chmod 777 /srv/shared
```
Editar configuração:
```txt
sudo nano /etc/samba/smb.conf
```
Adicionar no final:
```txt
[Shared]
   path = /srv/shared
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
```
Reiniciar Samba:
```txt
sudo systemctl restart smbd
```
Agora no Windows acessar:
```txt
\\IP_DO_SERVIDOR\Shared
```

### 7 — Instalar .NET 10

Adicionar repositório Microsoft:
```txt
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
```
Instalar SDK:
```txt
sudo apt install -y dotnet-sdk-10.0
```
Verificar:
```txt
dotnet --version
```

### 8 — Criar API ASP.NET

Criar pasta de aplicações:
```txt
sudo mkdir /opt/apps
cd /opt/apps
```
Criar API:
```txt
dotnet new webapi -n MinhaApi
```
Executar teste:
```txt
cd MinhaApi
dotnet run
```
Testar no navegador:
```txt
http://IP_DO_SERVIDOR:5000
```

### 9 — Publicar API

Publicar aplicação:
```txt
dotnet publish -c Release -o /opt/apps/minhaapi
```

### 10 — Criar serviço systemd

Criar serviço:
```txt
sudo nano /etc/systemd/system/minhaapi.service
```
Conteúdo:
```txt
[Unit]
Description=Minha API .NET
After=network.target

[Service]
WorkingDirectory=/opt/apps/minhaapi
ExecStart=/usr/bin/dotnet /opt/apps/minhaapi/MinhaApi.dll
Restart=always
RestartSec=10
SyslogIdentifier=minhaapi
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
```
Recarregar serviços:
```txt
sudo systemctl daemon-reload
```
Habilitar serviço:
```txt
sudo systemctl enable minhaapi
```
Iniciar:
```txt
sudo systemctl start minhaapi
```
Ver logs:
```txt
journalctl -u minhaapi -f
```

### 11 — (Opcional) Instalar Nginx

Instalar:
```txt
sudo apt install -y nginx
```
Criar configuração:
```txt
sudo nano /etc/nginx/sites-available/minhaapi
```
Conteúdo:
```txt
server {
    listen 80;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```
Ativar site:
```txt
sudo ln -s /etc/nginx/sites-available/minhaapi /etc/nginx/sites-enabled/
```
Testar:
```txt
sudo nginx -t
```
Reiniciar:
```txt
sudo systemctl restart nginx
```
Agora a API estará disponível em:
```txt
http://IP_DO_SERVIDOR
```

## Estrutura recomendada
```txt
/opt
 └── apps
      └── minhaapi

/srv
 └── shared
```

## Melhorias futuras

* Docker + Docker Compose
* Backup automático do PostgreSQL
* Certificado HTTPS (Let's Encrypt)
* Monitoramento com Prometheus + Grafana