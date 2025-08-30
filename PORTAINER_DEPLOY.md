# Deploy no Portainer - Gwan Logs

Guia passo a passo para fazer o deploy da stack de logs no Portainer.

## 🚀 **Deploy Rápido**

### **1. Preparação**
- Certifique-se de que o Portainer está rodando
- Tenha acesso ao servidor (69.62.99.103)
- Configure os DNS: `logs.gwan.com.br` e `kibana.gwan.com.br`

### **2. Deploy via Portainer**

1. **Acesse o Portainer**
   - URL: `http://69.62.99.103:9000` (ou porta configurada)
   - Faça login com suas credenciais

2. **Criar Nova Stack**
   - Vá em **"Stacks"** no menu lateral
   - Clique em **"Add stack"**

3. **Configurar Stack**
   - **Name**: `gwan-logs`
   - **Build method**: `Web editor`
   - **Repository URL**: `https://github.com/seu-usuario/gwan-logs.git`
   - **Repository reference**: `main`
   - **Repository authentication**: (deixe em branco se público)

4. **Colar o Docker Compose**
   - Copie todo o conteúdo do arquivo `docker-compose.yml`
   - Cole no campo **"Web editor"**

5. **Deploy**
   - Clique em **"Deploy the stack"**
   - Aguarde a criação dos containers

## 📋 **Configuração Pós-Deploy**

### **1. Verificar Status**
```bash
# No Portainer, vá em "Containers" e verifique:
✅ gwan-elasticsearch - Running
✅ gwan-kibana - Running  
✅ gwan-filebeat - Running
✅ gwan-logstash - Running
✅ gwan-nginx - Running
```

### **2. Configurar Variáveis de Ambiente**
1. Vá em **"Stacks"** → **"gwan-logs"** → **"Editor"**
2. Adicione as variáveis de ambiente no `docker-compose.yml`:
   ```yaml
   environment:
     - ELASTIC_PASSWORD=GwanLogs2024!
   ```

### **3. Acessar as Interfaces**
- **Interface principal**: `https://logs.gwan.com.br`
- **Kibana direto**: `https://kibana.gwan.com.br`
- **Credenciais**: `elastic` / `GwanLogs2024!`

## 🔧 **Configurações Importantes**

### **Volumes Persistentes**
Os dados são armazenados em:
- `/opt/gwan-logs/elasticsearch` - Dados do Elasticsearch
- `/opt/gwan-logs/kibana` - Configurações do Kibana
- `/opt/gwan-logs/filebeat` - Estado do Filebeat
- `/opt/gwan-logs/logstash` - Dados do Logstash

### **Portas Utilizadas**
- `80` - HTTP (redireciona para HTTPS)
- `443` - HTTPS (Nginx)
- `9200` - Elasticsearch API
- `5601` - Kibana (interno)

### **SSL/HTTPS**
- Certificados auto-assinados são gerados automaticamente
- Para certificados Let's Encrypt, configure manualmente

## 📊 **Primeiros Passos**

### **1. Criar Index Patterns**
1. Acesse `https://logs.gwan.com.br`
2. Vá em **"Stack Management"** → **"Index Patterns"**
3. Crie os padrões:
   - `gwan-logs-*`
   - `gwan-logs-nodejs-*`
   - `gwan-logs-python-*`

### **2. Configurar Dashboards**
1. Vá em **"Dashboard"**
2. Clique em **"Create dashboard"**
3. Adicione visualizações para:
   - Logs por aplicação
   - Logs por nível
   - Logs por tempo

### **3. Testar Coleta de Logs**
```bash
# Gerar log de teste
docker run --rm alpine echo "Test log from container $(date)" | logger
```

## 🛠️ **Manutenção**

### **Backup**
```bash
# Via Portainer Terminal
docker exec gwan-elasticsearch elasticsearch-dump \
  --input=http://localhost:9200/gwan-logs-* \
  --output=/backup/logs-backup.json
```

### **Logs dos Containers**
No Portainer:
1. Vá em **"Containers"**
2. Clique no container desejado
3. Vá na aba **"Logs"**

### **Restart de Serviços**
1. Vá em **"Stacks"** → **"gwan-logs"**
2. Clique em **"Restart"** para reiniciar toda a stack

## 🐛 **Troubleshooting**

### **Problemas Comuns**

1. **Elasticsearch não inicia**
   - Verifique se a porta 9200 está livre
   - Confirme espaço em disco
   - Verifique logs no Portainer

2. **Kibana não acessível**
   - Verifique se o Elasticsearch está rodando
   - Confirme as credenciais
   - Verifique logs do Kibana

3. **Filebeat não coleta logs**
   - Verifique permissões dos volumes
   - Confirme se os containers estão rodando
   - Verifique configuração do Filebeat

### **Comandos Úteis**
```bash
# Verificar status dos serviços
curl -u elastic:GwanLogs2024! http://localhost:9200/_cluster/health

# Verificar logs do Elasticsearch
docker logs gwan-elasticsearch

# Verificar logs do Kibana
docker logs gwan-kibana

# Verificar logs do Filebeat
docker logs gwan-filebeat
```

## 📞 **Suporte**

- **Documentação**: [docs/](docs/)
- **Issues**: GitHub do projeto
- **Email**: suporte@gwan.com.br

---

**✅ Stack pronta para produção!**
