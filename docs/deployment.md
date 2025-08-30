# Guia de Deployment - Gwan Logs

Este documento fornece instruções detalhadas para fazer o deployment do sistema de logs centralizado no seu servidor via Portainer.

## Pré-requisitos

### Requisitos de Sistema
- **Sistema Operacional**: Ubuntu 20.04+ ou CentOS 8+
- **CPU**: Mínimo 2 cores, recomendado 4+ cores
- **RAM**: Mínimo 4GB, recomendado 8GB+
- **Disco**: Mínimo 20GB livre, recomendado 50GB+
- **Rede**: Acesso à internet para download das imagens Docker

### Software Necessário
- Docker 20.10+
- Docker Compose 2.0+
- Git
- curl
- jq (para scripts de backup)

## Instalação

### 1. Preparação do Sistema

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y curl wget git jq openssl

# Instalar Docker (se não estiver instalado)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Configuração de DNS

Configure os seguintes registros DNS para apontar para o seu servidor:

```
logs.gwan.com.br     A    69.62.99.103
kibana.gwan.com.br   A    69.62.99.103
```

### 3. Configuração de SSL

#### Opção A: Certificados Let's Encrypt (Recomendado)

```bash
# Instalar Certbot
sudo apt install -y certbot

# Obter certificados
sudo certbot certonly --standalone -d logs.gwan.com.br -d kibana.gwan.com.br

# Copiar certificados para o diretório do projeto
sudo cp /etc/letsencrypt/live/logs.gwan.com.br/fullchain.pem configs/nginx/ssl/gwan.com.br.crt
sudo cp /etc/letsencrypt/live/logs.gwan.com.br/privkey.pem configs/nginx/ssl/gwan.com.br.key

# Configurar renovação automática
echo "0 12 * * * /usr/bin/certbot renew --quiet && cp /etc/letsencrypt/live/logs.gwan.com.br/fullchain.pem /path/to/gwan-logs/configs/nginx/ssl/gwan.com.br.crt && cp /etc/letsencrypt/live/logs.gwan.com.br/privkey.pem /path/to/gwan-logs/configs/nginx/ssl/gwan.com.br.key && docker-compose restart nginx" | sudo crontab -
```

#### Opção B: Certificados Auto-assinados (Desenvolvimento)

O script de instalação criará automaticamente certificados auto-assinados.

### 4. Configuração do Projeto

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/gwan-logs.git
cd gwan-logs

# Configurar variáveis de ambiente
cp env.example .env
nano .env  # Editar com suas configurações

# Criar diretórios necessários
sudo mkdir -p /opt/gwan-logs/{elasticsearch,kibana,filebeat,logstash,prometheus,backups}
sudo chown -R $USER:$USER /opt/gwan-logs
```

### 5. Deploy via Portainer

1. Acesse o Portainer no seu servidor
2. Vá em "Stacks" → "Add stack"
3. Configure:
   - **Name**: `gwan-logs`
   - **Build method**: `Web editor`
   - Cole o conteúdo do arquivo `docker-compose.yml`
4. Clique em "Deploy the stack"

### 6. Deploy Manual

```bash
# Executar script de instalação
sudo ./scripts/install.sh

# Ou fazer deploy manual
docker-compose up -d
```

## Configuração Pós-Deploy

### 1. Configuração de Índices

```bash
# Verificar se o Elasticsearch está respondendo
curl -u "elastic:GwanLogs2024!" http://localhost:9200/_cluster/health

# Configurar templates de índice
curl -u "elastic:GwanLogs2024!" -X PUT "http://localhost:9200/_template/gwan-logs-template" \
  -H "Content-Type: application/json" \
  -d @configs/elasticsearch/template.json
```

### 2. Configuração de Dashboards

1. Acesse `https://logs.gwan.com.br`
2. Faça login com `elastic` e a senha do `.env`
3. Vá em "Stack Management" → "Kibana" → "Index Patterns"
4. Crie os seguintes padrões:
   - `gwan-logs-*`
   - `gwan-logs-nodejs-*`
   - `gwan-logs-python-*`

### 3. Configuração de Alertas

```bash
# Criar regras de alerta no Kibana
# Vá em "Stack Management" → "Rules and Alerts" → "Create rule"
```

## Monitoramento

### 1. Verificação de Status

```bash
# Verificar status dos containers
docker-compose ps

# Verificar logs
docker-compose logs -f

# Verificar recursos do sistema
docker stats
```

### 2. Métricas de Performance

- **Elasticsearch**: `http://localhost:9200/_cluster/stats`
- **Kibana**: `http://localhost:5601/api/status`
- **Prometheus**: `http://localhost:9090`

### 3. Alertas

Configure alertas para:
- CPU > 80%
- Memória > 85%
- Disco > 90%
- Elasticsearch não respondendo
- Kibana não acessível

## Backup e Restore

### 1. Backup Automático

```bash
# Configurar cron job para backup diário
echo "0 2 * * * /path/to/gwan-logs/scripts/backup.sh" | crontab -

# Executar backup manual
./scripts/backup.sh
```

### 2. Restore

```bash
# Restaurar configurações
tar -xzf backup-config.tar.gz

# Restaurar dados do Elasticsearch
curl -u "elastic:GwanLogs2024!" -X POST "http://localhost:9200/_snapshot/gwan-backup-repo/snapshot-20240101/_restore" \
  -H "Content-Type: application/json" \
  -d '{"indices": "gwan-logs-*"}'
```

## Troubleshooting

### Problemas Comuns

1. **Elasticsearch não inicia**
   ```bash
   # Verificar logs
   docker-compose logs elasticsearch
   
   # Verificar permissões
   sudo chown -R 1000:1000 /opt/gwan-logs/elasticsearch
   ```

2. **Kibana não acessível**
   ```bash
   # Verificar se o Elasticsearch está respondendo
   curl -u "elastic:GwanLogs2024!" http://localhost:9200
   
   # Verificar logs do Kibana
   docker-compose logs kibana
   ```

3. **Filebeat não coleta logs**
   ```bash
   # Verificar permissões
   sudo chmod 644 /var/lib/docker/containers/*/*.log
   
   # Verificar configuração
   docker-compose exec filebeat filebeat test config
   ```

### Logs Importantes

```bash
# Logs do Elasticsearch
docker-compose logs elasticsearch

# Logs do Kibana
docker-compose logs kibana

# Logs do Filebeat
docker-compose logs filebeat

# Logs do Nginx
docker-compose logs nginx
```

## Segurança

### 1. Firewall

```bash
# Configurar UFW
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 2. Autenticação

- Use senhas fortes no arquivo `.env`
- Configure autenticação básica no Nginx
- Use HTTPS sempre

### 3. Monitoramento de Segurança

- Configure alertas para tentativas de login falhadas
- Monitore logs de acesso
- Use certificados SSL válidos

## Escalabilidade

### 1. Aumentar Recursos

```yaml
# No docker-compose.yml
elasticsearch:
  environment:
    - "ES_JAVA_OPTS=-Xms4g -Xmx4g"  # Aumentar heap
```

### 2. Adicionar Nodes

```yaml
# Configurar cluster multi-node
elasticsearch:
  environment:
    - discovery.type=multi-node
    - discovery.seed_hosts=elasticsearch1,elasticsearch2
```

### 3. Backup em Nuvem

```bash
# Configurar backup para S3
# Adicionar no script de backup
aws s3 cp backup.tar.gz s3://gwan-logs-backups/
```

## Manutenção

### 1. Atualizações

```bash
# Atualizar imagens
docker-compose pull
docker-compose up -d

# Verificar compatibilidade
docker-compose logs
```

### 2. Limpeza

```bash
# Limpar logs antigos
docker system prune -f

# Limpar backups antigos
find /opt/gwan-logs/backups -name "*.tar.gz" -mtime +30 -delete
```

### 3. Monitoramento Contínuo

- Configure alertas por email
- Monitore métricas de performance
- Faça backup regular
- Verifique logs periodicamente
