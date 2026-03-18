# XControlFin API - Linux Deployment Guide

Este documento descreve o processo de **publicação e execução da API .NET XControlFin em um servidor Linux** utilizando **systemd**.

O ambiente utilizado neste exemplo:

- Linux (Zorin OS / Ubuntu-based)
- .NET Runtime
- Kestrel
- systemd
- Scalar OpenAPI

---

# 1. Estrutura de diretórios

A aplicação é publicada em:


/opt/apps/XControlFin/publish


Estrutura típica após o publish:


/opt/apps/XControlFin/publish
│
├── xControlFin.dll
├── xControlFin.deps.json
├── xControlFin.runtimeconfig.json
├── appsettings.json
├── appsettings.Production.json
└── outros arquivos da aplicação


---

# 2. Publicação da aplicação

Executar no projeto da API:

```txt
dotnet publish -c Release -o /opt/apps/XControlFin/publish

Isso gera a versão pronta para execução no servidor.

3. Configuração do serviço systemd

Criar o arquivo:

/etc/systemd/system/xcontrolfin.service

Conteúdo do serviço:

[Unit]
Description=XControlFin API
After=network.target

[Service]
WorkingDirectory=/opt/apps/XControlFin/publish
ExecStart=/usr/bin/dotnet /opt/apps/XControlFin/publish/xControlFin.dll

Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=xcontrolfin

User=andreotti

Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
4. Ativar o serviço

Recarregar systemd:

sudo systemctl daemon-reload

Habilitar inicialização automática:

sudo systemctl enable xcontrolfin

Iniciar serviço:

sudo systemctl start xcontrolfin

Reiniciar serviço:

sudo systemctl restart xcontrolfin

Parar serviço:

sudo systemctl stop xcontrolfin

Ver status:

sudo systemctl status xcontrolfin
5. Logs da aplicação

Visualizar logs em tempo real:

sudo journalctl -u xcontrolfin -f

Últimas 100 linhas:

sudo journalctl -u xcontrolfin -n 100 --no-pager
6. Verificar se a aplicação está rodando

Verificar porta utilizada pelo Kestrel:

sudo ss -tulpn | grep 5000
7. Testes da API

Testar localmente:

curl -i http://localhost:5000

Testar documentação:

curl -i http://localhost:5000/scalar

Testar OpenAPI:

curl -i http://localhost:5000/openapi/v1.json
8. Acesso pelo navegador

Local:

http://localhost:5000/scalar

Outro computador da rede:

http://IP_DO_SERVIDOR:5000/scalar
9. Descobrir IP do servidor
hostname -I

Exemplo:

192.168.0.15

Acesso remoto:

http://192.168.0.15:5000/scalar
10. Firewall

Verificar firewall:

sudo ufw status

Liberar porta da API:

sudo ufw allow 5000/tcp
11. Configuração necessária no Program.cs

A documentação OpenAPI precisa estar disponível em Production.

Trecho recomendado:

app.MapOpenApi();

app.MapScalarApiReference((options, context) =>
{
    var basePath = context.Request.PathBase.HasValue ? context.Request.PathBase.Value : "";
    options.OpenApiRoutePattern = $"{basePath}/openapi/{{documentName}}.json";
    options.Theme = ScalarTheme.Solarized;
    options.Title = "XControlFin - Controle Financeiro";
    options.Layout = ScalarLayout.Modern;
    options.OperationSorter = OperationSorter.Alpha;
    options.TagSorter = TagSorter.Alpha;
});

Redirect da raiz:

app.MapGet("/", context =>
{
    context.Response.Redirect("/scalar");
    return Task.CompletedTask;
});
12. Publicar novamente após alteração
dotnet publish -c Release -o /opt/apps/XControlFin/publish

Reiniciar serviço:

sudo systemctl restart xcontrolfin
13. Checklist de funcionamento

✔ Serviço rodando
✔ Porta 5000 aberta
✔ API respondendo
✔ Scalar UI disponível
✔ OpenAPI gerado
✔ Acesso pela rede funcionando

14. Arquitetura final
Linux Server
     │
systemd
     │
dotnet
     │
Kestrel
     │
XControlFin API
     │
Scalar OpenAPI
15. Comandos principais
Publicar aplicação
dotnet publish -c Release -o /opt/apps/XControlFin/publish
Reiniciar API
sudo systemctl restart xcontrolfin
Ver logs
sudo journalctl -u xcontrolfin -f
Testar API
curl http://localhost:5000
16. Melhorias futuras

Recomendações para produção:

Nginx Reverse Proxy

HTTPS com Let's Encrypt

Monitoramento

Health Check endpoint

Logs centralizados

Docker

Autor

Projeto XControlFin
API de Controle Financeiro