# Gwan Logs - Sistema de Logs Centralizado

Sistema de logs centralizado para aplicações Node.js e Python rodando no Portainer, utilizando Elasticsearch, Kibana e Filebeat.

## 🏗️ Arquitetura

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Aplicações │    │   Filebeat   │    │ Elasticsearch│    │   Kibana    │
│  (Node.js/   │───▶│   (Coleta)   │───▶│ (Armazenamento)│───▶│ (Visualização)│
│   Python)    │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Portainer configurado
- Acesso ao servidor (69.62.99.103)
- Aproximadamente 10GB de espaço em disco para logs

## 🚀 Instalação

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/gwan-logs.git
cd gwan-logs
```

### 2. Configure as variáveis de ambiente
```bash
cp .env.example .env
# Edite o arquivo .env com suas configurações
```

### 3. Deploy via Portainer
1. Acesse o Portainer
2. Vá em "Stacks" → "Add stack"
3. Nome: `gwan-logs`
4. Cole o conteúdo do arquivo `docker-compose.yml`
5. Clique em "Deploy the stack"

### 4. Acesse as interfaces
- **Interface principal**: `https://logs.gwan.com.br` (Kibana via proxy)
- **Kibana direto**: `https://kibana.gwan.com.br` (acesso direto com autenticação)
- Usuário padrão: `elastic`
- Senha: definida no arquivo `.env`

> **💡 Nota**: Este repositório contém apenas o módulo de logs. Para monitoramento completo, consulte o repositório `gwan-monitoring`

## 🔧 Configuração das Aplicações

### Para aplicações Node.js
Adicione o seguinte no seu `package.json`:
```json
{
  "dependencies": {
    "winston": "^3.11.0",
    "winston-elasticsearch": "^0.17.0"
  }
}
```

E configure o logger:
```javascript
const winston = require('winston');
const ElasticsearchTransport = require('winston-elasticsearch').ElasticsearchTransport;

const logger = winston.createLogger({
  transports: [
    new winston.transports.Console(),
    new ElasticsearchTransport({
      level: 'info',
      clientOpts: {
        node: 'http://elasticsearch:9200',
        index: 'logs-nodejs'
      }
    })
  ]
});
```

### Para aplicações Python
Instale as dependências:
```bash
pip install python-json-logger elasticsearch
```

Configure o logger:
```python
import logging
from pythonjsonlogger import jsonlogger
from elasticsearch import Elasticsearch

# Configurar logger JSON
logger = logging.getLogger()
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Opcional: Enviar diretamente para Elasticsearch
es = Elasticsearch(['http://elasticsearch:9200'])
```

## 📊 Visualização de Logs

### Dashboards Disponíveis
- **Logs por Aplicação**: Visualização de logs por container/aplicação
- **Logs por Nível**: Distribuição de logs por nível (INFO, ERROR, WARN, DEBUG)
- **Logs por Tempo**: Análise temporal dos logs
- **Erros e Exceções**: Monitoramento de erros em tempo real

### Alertas Básicos
Configure alertas no Kibana para:
- Taxa de erro > 5%
- Aplicação não respondendo
- Logs de erro críticos

> **💡 Nota**: Para alertas avançados e métricas de performance, use o módulo de monitoramento separado

## 🔒 Segurança

- Autenticação básica habilitada
- HTTPS configurado
- Logs sensíveis filtrados
- Backup automático dos dados

## 📈 Escalabilidade

O sistema foi projetado para:
- Suportar até 50 aplicações simultâneas
- Processar 10.000 logs por minuto
- Armazenar 30 dias de logs por padrão
- Backup automático diário

## 🛠️ Manutenção

### Backup
```bash
# Backup dos dados do Elasticsearch
docker exec gwan-logs_elasticsearch_1 elasticsearch-dump --input=http://localhost:9200/logs --output=backup.json
```

### Limpeza de Logs Antigos
Configure a política de retenção no Kibana:
- Logs de DEBUG: 7 dias
- Logs de INFO: 15 dias
- Logs de ERROR: 30 dias

### Monitoramento do Sistema
- CPU: < 80%
- Memória: < 85%
- Disco: < 90%

## 🐛 Troubleshooting

### Problemas Comuns

1. **Elasticsearch não inicia**
   - Verifique se a porta 9200 está livre
   - Confirme se há espaço suficiente em disco

2. **Filebeat não coleta logs**
   - Verifique as permissões dos volumes
   - Confirme se os containers estão rodando

3. **Kibana não acessível**
   - Verifique se a porta 5601 está exposta
   - Confirme as credenciais no arquivo `.env`

### Logs do Sistema
```bash
# Logs do Elasticsearch
docker logs gwan-logs_elasticsearch_1

# Logs do Kibana
docker logs gwan-logs_kibana_1

# Logs do Filebeat
docker logs gwan-logs_filebeat_1
```

## 📞 Suporte

Para suporte técnico:
- Abra uma issue no GitHub
- Email: suporte@gwan.com.br
- Documentação: [Wiki do Projeto](link-para-wiki)

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Desenvolvido para Gwan.com.br** 🚀
