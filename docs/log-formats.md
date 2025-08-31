# 📋 Guia de Formatos de Log - Gwan Logs

## 🎯 **Onde Configurar Formatos de Log**

### **1. 🐳 Filebeat (Coleta de Containers)**

**Arquivo**: `configs/filebeat/filebeat.yml`

**Formatos configurados**:
- **JSON estruturado** com metadados
- **Filtros** para logs desnecessários
- **Processamento** com JavaScript
- **Índices** organizados por data

**Exemplo de log formatado**:
```json
{
  "@timestamp": "2025-08-31T00:50:47.993Z",
  "level": "INFO",
  "message": "HTTP Request",
  "service": "gwan-app",
  "environment": "production",
  "hostname": "server-01",
  "container": "gwan-app-1",
  "method": "GET",
  "url": "/api/users",
  "status": 200,
  "duration": "150ms"
}
```

### **2. 📝 Aplicações Node.js**

**Arquivo**: `examples/nodejs/logger.js`

**Formatos configurados**:
- **Winston** com formato personalizado
- **Elasticsearch transport** direto
- **Middleware** para Express
- **Funções** específicas (erro, performance, segurança)

**Exemplo de uso**:
```javascript
const { logger, logError, logPerformance } = require('./logger');

// Log básico
logger.info('Usuário logado', { userId: '123', ip: '192.168.1.1' });

// Log de erro
logError(new Error('Erro de conexão'), { context: 'database' });

// Log de performance
logPerformance('database_query', 150, { table: 'users' });
```

### **3. 🐍 Aplicações Python**

**Arquivo**: `examples/python/logger.py`

**Formatos configurados**:
- **JSON logger** estruturado
- **Elasticsearch handler** personalizado
- **Templates** de índice automáticos
- **Funções** específicas por tipo

**Exemplo de uso**:
```python
from logger import GwanLogger

logger = GwanLogger(service_name='api-service')

# Log básico
logger.info('Requisição processada', user_id='123', endpoint='/api/users')

# Log de erro
try:
    # código que pode dar erro
    pass
except Exception as e:
    logger.error('Erro na API', error=e, context='user_creation')

# Log de performance
logger.performance('database_query', 150, table='users')
```

### **4. 🎨 Kibana (Visualização)**

**Configurações no Kibana**:

#### **Index Patterns**
1. Vá em **"Stack Management"** → **"Index Patterns"**
2. Crie padrões para:
   - `gwan-logs-*` (logs gerais)
   - `gwan-logs-error-*` (erros)
   - `gwan-logs-performance-*` (performance)

#### **Visualizações**
1. **Logs por nível**: Gráfico de pizza por `level`
2. **Logs por serviço**: Gráfico de barras por `service`
3. **Performance**: Gráfico de linha por `duration_ms`
4. **Erros**: Tabela filtrada por `level: ERROR`

#### **Dashboards**
1. **Dashboard Geral**: Visão geral de todos os logs
2. **Dashboard de Erros**: Foco em erros e warnings
3. **Dashboard de Performance**: Métricas de performance
4. **Dashboard de Segurança**: Eventos de segurança

## 🔧 **Campos Padrão dos Logs**

### **Campos Obrigatórios**:
- `@timestamp`: Data/hora do log
- `level`: Nível (INFO, ERROR, WARN, DEBUG)
- `message`: Mensagem principal
- `service`: Nome do serviço
- `environment`: Ambiente (production, development)

### **Campos Opcionais**:
- `hostname`: Nome do servidor
- `pid`: ID do processo
- `version`: Versão da aplicação
- `user_id`: ID do usuário
- `request_id`: ID da requisição
- `duration_ms`: Duração em milissegundos
- `error`: Detalhes do erro (stack, code)

### **Campos Específicos**:
- `log_type`: Tipo do log (performance, security, audit)
- `operation`: Operação sendo executada
- `resource`: Recurso sendo acessado
- `ip`: IP do cliente
- `user_agent`: User agent do navegador

## 📊 **Exemplos de Queries no Kibana**

### **Logs de Erro**:
```
level: ERROR
```

### **Logs de Performance**:
```
log_type: performance AND duration_ms > 1000
```

### **Logs de Segurança**:
```
log_type: security
```

### **Logs de um Serviço Específico**:
```
service: "gwan-api"
```

### **Logs de uma Data**:
```
@timestamp: [2025-08-31 TO 2025-09-01]
```

## 🎯 **Próximos Passos**

1. **Configure Filebeat** no docker-compose.yml
2. **Integre os loggers** nas suas aplicações
3. **Crie dashboards** no Kibana
4. **Configure alertas** para logs críticos

## 📝 **Notas Importantes**

- **Logs são indexados** por data (`gwan-logs-YYYY.MM.DD`)
- **ILM policies** configuradas para retenção automática
- **Templates** criados automaticamente
- **Segurança** ativa com autenticação
