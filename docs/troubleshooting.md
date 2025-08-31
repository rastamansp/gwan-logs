# 🔧 Guia de Troubleshooting - Gwan Logs

## 🚨 **Problemas Comuns e Soluções**

### **1. ❌ "Container gwan-elasticsearch is unhealthy"**

**Causas possíveis:**
- Elasticsearch demorando para inicializar
- Pouca memória disponível
- Problemas com volumes
- Configurações muito restritivas

**Soluções:**

#### **A. Ajustar Configurações (já feito)**
```yaml
# docker-compose.yml
healthcheck:
  interval: 120s      # Verificar a cada 2 minutos
  timeout: 60s        # Timeout de 1 minuto
  retries: 5          # 5 tentativas
  start_period: 300s  # 5 minutos para inicializar
```

#### **B. Verificar Recursos**
```bash
# Verificar memória disponível
free -h

# Verificar espaço em disco
df -h

# Verificar uso de CPU
top
```

#### **C. Limpar e Recriar**
```bash
# Parar stack
docker-compose down

# Remover volumes (CUIDADO: perde dados!)
docker volume rm gwan-logs_es_data_external gwan-logs_kb_data_external

# Recriar volumes no Portainer
# Depois subir novamente
docker-compose up -d
```

### **2. ⏳ Elasticsearch Demorando para Inicializar**

**Logs típicos:**
```
INFO cluster UUID [xxx] 
INFO elected-as-master
INFO started
```

**Isso é NORMAL!** O Elasticsearch leva tempo para:
- Inicializar JVM
- Criar índices
- Configurar segurança
- Baixar plugins

**Tempo esperado:** 3-5 minutos

### **3. 🔍 Como Verificar se Está Funcionando**

#### **A. Verificar Containers**
```bash
docker ps --filter "name=gwan-"
```

**Status esperado:**
- `Up (healthy)` - Funcionando
- `Up (unhealthy)` - Problema
- `Exited` - Parado

#### **B. Verificar Logs**
```bash
# Elasticsearch
docker logs gwan-elasticsearch

# Kibana
docker logs gwan-kibana
```

#### **C. Testar Elasticsearch**
```bash
# Testar conexão
curl -u elastic:GwanLogs2024! http://localhost:9200/_cluster/health

# Resposta esperada:
{
  "cluster_name": "docker-cluster",
  "status": "green",
  "number_of_nodes": 1
}
```

#### **D. Testar Kibana**
```bash
# Testar API
curl http://localhost:5601/api/status

# Acessar via navegador
https://logs.gwan.com.br
```

### **4. 🐳 Problemas com Docker/Portainer**

#### **A. Volumes Externos**
- **Criar no Portainer**: Volumes → Add Volume
- **Nomes**: `es_data_external`, `kb_data_external`
- **Driver**: local

#### **B. Rede Externa**
- **Criar no Portainer**: Networks → Add Network
- **Nome**: `gwan`
- **Driver**: bridge

#### **C. Permissões**
```bash
# Verificar permissões dos volumes
ls -la /var/lib/docker/volumes/

# Corrigir se necessário
chown -R 1000:1000 /var/lib/docker/volumes/gwan-logs_*
```

### **5. 🔧 Comandos Úteis**

#### **A. Reiniciar Serviços**
```bash
# Reiniciar apenas Elasticsearch
docker-compose restart elasticsearch

# Reiniciar apenas Kibana
docker-compose restart kibana

# Reiniciar tudo
docker-compose restart
```

#### **B. Ver Logs em Tempo Real**
```bash
# Elasticsearch
docker logs -f gwan-elasticsearch

# Kibana
docker logs -f gwan-kibana
```

#### **C. Entrar no Container**
```bash
# Elasticsearch
docker exec -it gwan-elasticsearch bash

# Kibana
docker exec -it gwan-kibana bash
```

### **6. 📊 Monitoramento**

#### **A. Status do Cluster**
```bash
curl -u elastic:GwanLogs2024! http://localhost:9200/_cluster/health
```

**Status possíveis:**
- `green`: Tudo OK
- `yellow`: Alguns problemas
- `red`: Problemas críticos

#### **B. Índices**
```bash
curl -u elastic:GwanLogs2024! http://localhost:9200/_cat/indices
```

#### **C. Nodes**
```bash
curl -u elastic:GwanLogs2024! http://localhost:9200/_cat/nodes
```

### **7. 🚀 Otimizações**

#### **A. Memória**
```yaml
# Reduzir uso de memória
ES_JAVA_OPTS: "-Xms256m -Xmx256m"
```

#### **B. Performance**
```yaml
# Desabilitar recursos desnecessários
ingest.geoip.downloader.enabled: false
cluster.routing.allocation.disk.threshold_enabled: false
```

#### **C. Logs**
```yaml
# Reduzir verbosidade
logging.level: warn
```

### **8. 📞 Suporte**

**Se nada funcionar:**
1. Verificar logs completos
2. Verificar recursos do sistema
3. Tentar versão mais antiga (6.x)
4. Verificar configurações de rede

**Logs importantes:**
- `/var/log/docker/` - Logs do Docker
- `/var/log/syslog` - Logs do sistema
- Logs dos containers via `docker logs`
