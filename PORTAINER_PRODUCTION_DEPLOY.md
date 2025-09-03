# 🚀 Deploy no Portainer - Gwan Logs

Guia completo para deploy da stack de logs no Portainer em produção.

## 📋 **Pré-requisitos**

- Portainer rodando no servidor
- Acesso SSH ao servidor (69.62.99.103)
- Git configurado no servidor
- Docker e Docker Compose instalados

## 🔧 **Preparação do Servidor**

### 1. **Conectar ao Servidor**
```bash
ssh root@69.62.99.103
```

### 2. **Criar Diretório do Projeto**
```bash
mkdir -p /opt/gwan-logs
cd /opt/gwan-logs
```

### 3. **Clonar o Repositório**
```bash
git clone https://github.com/rastamansp/gwan-logs.git .
```

### 4. **Criar Rede Docker**
```bash
docker network create gwan
```

### 5. **Configurar Variáveis de Ambiente**
```bash
cp env.production .env
# Editar o arquivo .env conforme necessário
nano .env
```

## 🎯 **Deploy via Portainer**

### **Opção 1: Deploy via Web Editor**

1. **Acesse o Portainer**
   - URL: `http://69.62.99.103:9000`
   - Faça login com suas credenciais

2. **Criar Nova Stack**
   - Vá em **"Stacks"** no menu lateral
   - Clique em **"Add stack"**

3. **Configurar Stack**
   - **Name**: `gwan-logs`
   - **Build method**: `Web editor`
   - **Repository URL**: `https://github.com/rastamansp/gwan-logs.git`
   - **Repository reference**: `main`
   - **Repository authentication**: (deixe em branco se público)

4. **Colar o Docker Compose**
   - Copie todo o conteúdo do arquivo `docker-compose.production.yml`
   - Cole no campo **"Web editor"**

5. **Deploy**
   - Clique em **"Deploy the stack"**
   - Aguarde a criação dos containers

### **Opção 2: Deploy via Repository**

1. **Configurar Stack**
   - **Name**: `gwan-logs`
   - **Build method**: `Repository`
   - **Repository URL**: `https://github.com/rastamansp/gwan-logs.git`
   - **Repository reference**: `main`
   - **Compose file**: `docker-compose.production.yml`

2. **Deploy**
   - Clique em **"Deploy the stack"**

## 📊 **Verificação do Deploy**

### 1. **Verificar Status dos Containers**
No Portainer:
- Vá em **"Containers"**
- Verifique se todos estão com status **"Running"**:
  - ✅ `gwan-elasticsearch` - Running
  - ✅ `gwan-kibana` - Running  
  - ✅ `gwan-logstash` - Running
  - ✅ `gwan-otel-collector` - Running
  - ✅ `gwan-jaeger` - Running
  - ✅ `gwan-prometheus` - Running
  - ✅ `gwan-alertmanager` - Running

### 2. **Verificar Health Checks**
```bash
# No terminal do servidor
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### 3. **Testar Elasticsearch**
```bash
curl -u "elastic:GwanLogs2024!" "http://localhost:9200/_cluster/health"
```

### 4. **Testar Kibana**
```bash
curl -f "http://localhost:5601/api/status"
```

## 🔗 **URLs de Acesso**

### **Interfaces Principais:**
- **Kibana**: `http://69.62.99.103:5601`
- **Elasticsearch API**: `http://69.62.99.103:9200`

### **Monitoramento:**
- **Prometheus**: `http://69.62.99.103:9090`
- **Alertmanager**: `http://69.62.99.103:9093`
- **Jaeger (Traces)**: `http://69.62.99.103:16686`

### **Coleta de Dados:**
- **Logstash**: `http://69.62.99.103:5044` (Beats) / `http://69.62.99.103:9600` (HTTP)
- **OTEL Collector**: `http://69.62.99.103:4318` (HTTP) / `69.62.99.103:4317` (gRPC)

## 🔐 **Credenciais**

- **Usuário**: `elastic`
- **Senha**: `GwanLogs2024!`

## 📝 **Configuração Pós-Deploy**

### 1. **Criar Index Patterns no Kibana**
1. Acesse `http://69.62.99.103:5601`
2. Faça login com as credenciais
3. Vá em **"Stack Management"** → **"Index Patterns"**
4. Crie os padrões:
   - `gwan-logs-*`
   - `gwan-logs-nodejs-*`
   - `gwan-logs-python-*`

### 2. **Configurar Dashboards**
1. Vá em **"Dashboard"**
2. Clique em **"Create dashboard"**
3. Adicione visualizações para:
   - Logs por aplicação
   - Logs por nível
   - Logs por tempo
   - Métricas de performance

### 3. **Configurar Alertas**
1. Vá em **"Stack Management"** → **"Rules and Alerts"**
2. Crie alertas para:
   - Erros críticos
   - Performance degradada
   - Espaço em disco baixo

## 🛠️ **Manutenção**

### **Comandos Úteis no Portainer:**

```bash
# Ver logs de um container
docker logs gwan-elasticsearch

# Reiniciar um serviço
docker restart gwan-kibana

# Verificar uso de recursos
docker stats

# Backup dos dados
docker exec gwan-elasticsearch elasticsearch-dump \
  --input=http://localhost:9200/gwan-logs-* \
  --output=/backup/logs-backup.json
```

### **Monitoramento de Recursos:**
- **CPU**: Monitorar uso por container
- **Memória**: Verificar limites configurados
- **Disco**: Acompanhar crescimento dos volumes
- **Rede**: Monitorar tráfego de logs

## 🔧 **Troubleshooting**

### **Problemas Comuns:**

1. **Elasticsearch não inicia**
   - Verificar espaço em disco
   - Verificar memória disponível
   - Verificar logs: `docker logs gwan-elasticsearch`

2. **Kibana não acessível**
   - Verificar se Elasticsearch está rodando
   - Verificar credenciais
   - Verificar logs: `docker logs gwan-kibana`

3. **Logstash não processa logs**
   - Verificar conexão com Elasticsearch
   - Verificar configuração dos pipelines
   - Verificar logs: `docker logs gwan-logstash`

### **Comandos de Diagnóstico:**
```bash
# Verificar status do cluster
curl -u "elastic:GwanLogs2024!" "http://localhost:9200/_cluster/health?pretty"

# Verificar índices
curl -u "elastic:GwanLogs2024!" "http://localhost:9200/_cat/indices?v"

# Verificar logs do sistema
docker-compose logs -f elasticsearch
```

## 📈 **Escalabilidade**

### **Para Aumentar Performance:**
1. **Elasticsearch**: Aumentar heap size e adicionar nós
2. **Logstash**: Aumentar workers e batch size
3. **Kibana**: Configurar cache e otimizações

### **Para Alta Disponibilidade:**
1. **Elasticsearch**: Configurar cluster multi-nó
2. **Logstash**: Usar múltiplas instâncias
3. **Kibana**: Configurar load balancer

## 🔒 **Segurança**

### **Recomendações:**
1. **Alterar senhas padrão**
2. **Configurar SSL/TLS**
3. **Implementar autenticação LDAP**
4. **Configurar firewalls**
5. **Monitorar acessos**

## 📞 **Suporte**

- **Documentação**: [docs/](docs/)
- **Issues**: GitHub do projeto
- **Email**: suporte@gwan.com.br

---

**✅ Stack pronta para produção!**

### **Próximos Passos:**
1. Configurar aplicações para enviar logs
2. Implementar backup automático
3. Configurar monitoramento de recursos
4. Treinar equipe no uso do Kibana
