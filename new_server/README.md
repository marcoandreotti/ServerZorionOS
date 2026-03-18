# Linux Server Setup for .NET APIs, Databases and Automation

Este repositório contém um **setup completo para transformar um Linux em servidor de aplicações**.

Ele prepara o ambiente para rodar:

* APIs **.NET**
* **PostgreSQL**
* **Redis**
* **n8n**
* **Ollama (IA local)**
* **Samba (compartilhamento de arquivos)**
* **Nginx (proxy reverso)**

Ideal para:

* servidores locais
* laboratórios
* desenvolvimento
* produção leve

---

# Arquitetura

```
Internet / Rede Local
        │
        ▼
      Nginx
        │
 ┌──────┼───────────────┬─────────────┐
 │      │               │             │
 ▼      ▼               ▼             ▼
.NET API  n8n        Ollama        Samba
 │         │           │
 │         │           │
 ├────► PostgreSQL     │
 │
 └────► Redis
```

---

# Estrutura de diretórios

```
/opt/apps/
  ├── XControlFin/
  │   └── publish/
  ├── scripts/
  └── backups/

/srv/
  └── samba/
      ├── public/
      └── private/
```

---

# 1. Preparar o servidor

Execute:

```
chmod +x setup-server.sh
./setup-server.sh
```

O script instala:

* Docker
* Nginx
* PostgreSQL
* Redis
* Samba
* .NET Runtime

---

# 2. Subir containers

```
docker compose up -d
```

Serviços criados:

| Serviço    | Porta |
| ---------- | ----- |
| PostgreSQL | 5432  |
| Redis      | 6379  |
| n8n        | 5678  |
| Ollama     | 11434 |

---

# 3. Publicar a API

```
dotnet publish -c Release -o /opt/apps/XControlFin/publish
```

---

# 4. Instalar serviço systemd

Copiar o arquivo:

```
sudo cp services/xcontrolfin.service /etc/systemd/system/
```

Recarregar serviços:

```
sudo systemctl daemon-reload
sudo systemctl enable xcontrolfin
sudo systemctl start xcontrolfin
```

---

# 5. Ver logs

```
sudo journalctl -u xcontrolfin -f
```

---

# 6. Testar API

```
http://IP_DO_SERVIDOR:5000/scalar
```

---

# 7. Testar serviços

| Serviço     | URL                       |
| ----------- | ------------------------- |
| API         | http://server:5000        |
| Scalar Docs | http://server:5000/scalar |
| n8n         | http://server:5678        |
| Ollama      | http://server:11434       |

---

# Segurança recomendada

* usar Nginx como proxy
* ativar HTTPS com certbot
* limitar acesso ao PostgreSQL
* Redis apenas localhost

---

# Próximos passos

Recomendado evoluir para:

* monitoramento
* backup automático
* health checks
* CI/CD
* autenticação centralizada

---

# Autor

XControlFin
Controle Financeiro
