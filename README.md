# Gwan Logs - Sistema de Logs Centralizado com OpenTelemetry

Sistema de logs centralizado para aplicações Node.js e Python rodando no Portainer, utilizando Elasticsearch, Kibana, Logstash e OpenTelemetry para observabilidade completa.

## 🏗️ Arquitetura

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Aplicações │    │   Filebeat   │    │ Elasticsearch│    │   Kibana    │
│  (Node.js/   │───▶│   (Coleta)   │───▶│ (Armazenamento)│───▶│ (Visualização)│
│   Python)    │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                │
                                ▼
                    ┌─────────────────┐
                    │   Logstash      │
                    │ (Processamento) │
                    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────┐
                    │ OpenTelemetry   │
                    │   Collector     │
                    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────┐    ┌─────────────────┐
                    │    Jaeger       │    │   Prometheus    │
                    │ (Traces/Spans)  │    │   (Métricas)    │
                    └─────────────────┘    └─────────────────┘
```

## 🔍 Observabilidade Completa

### OpenTelemetry Integration

O sistema agora inclui **OpenTelemetry** para observabilidade completa com:

#### 📊 **Métricas (Metrics)**
- **Contadores**: Total de requisições, erros, operações
- **Histogramas**: Duração de requisições, latência
- **Gauges**: Uso de memória, CPU, conexões ativas
- **Auto-instrumentação**: Métricas automáticas do sistema

#### 🔗 **Traces (Rastreamento)**
- **Spans distribuídos**: Rastreamento de requisições entre serviços
- **Contexto distribuído**: Propagação de contexto entre aplicações
- **Latência**: Medição de tempo de resposta
- **Dependências**: Mapeamento de chamadas entre serviços

#### 📝 **Logs Estruturados**
- **Correlação**: Logs vinculados a traces via TraceId/SpanId
- **Formato JSON**: Logs estruturados e padronizados
- **Filtros**: Remoção automática de dados sensíveis
- **Enriquecimento**: Adição de metadados automáticos

### Fluxo de Dados OpenTelemetry

```
Aplicação Node.js/Python
    │
    ├── Logs ──────────────▶ Logstash ──▶ Elasticsearch
    │
    ├── Traces ────────────▶ OpenTelemetry Collector ──▶ Jaeger
    │
    ├── Metrics ───────────▶ OpenTelemetry Collector ──▶ Prometheus
    │
    └── Logs (OTLP) ───────▶ OpenTelemetry Collector ──▶ Logstash
```

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Portainer configurado
- Acesso ao servidor (69.62.99.103)
- Aproximadamente 15GB de espaço em disco para logs e telemetria
- Node.js 16+ para aplicações com OpenTelemetry

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
- **Kibana**: `https://kibana.gwan.com.br` (Logs e Visualização)
- **Jaeger**: `https://jaeger.gwan.com.br` (Traces e Spans)
- **OpenTelemetry Collector**: `https://otel.gwan.com.br` (Métricas)
- **Elasticsearch**: `https://elasticsearch.gwan.com.br` (API REST)

> **💡 Nota**: Este repositório contém apenas o módulo de logs. Para monitoramento completo, consulte o repositório `gwan-monitoring`

## 🔧 Configuração das Aplicações

### Para aplicações Node.js com OpenTelemetry

#### 1. Instalar dependências
```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-http @opentelemetry/exporter-metrics-otlp-http winston winston-elasticsearch
```

#### 2. Configurar OpenTelemetry
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');

// Configuração do OpenTelemetry
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'minha-app',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    environment: 'production',
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://localhost:4318/v1/traces',
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: 'http://localhost:4318/v1/metrics',
    }),
    exportIntervalMillis: 1000,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

// Inicializa o SDK
sdk.start();
```

#### 3. Configurar Logger com Winston
```javascript
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');
const { trace } = require('@opentelemetry/api');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new ElasticsearchTransport({
      level: 'info',
      clientOpts: {
        node: 'http://elasticsearch:9200',
        index: 'gwan-logs'
      }
    })
  ]
});

// Middleware para Express com OpenTelemetry
const loggerMiddleware = (req, res, next) => {
  const start = Date.now();
  const tracer = trace.getTracer('minha-app');
  
  const span = tracer.startSpan('http-request', {
    attributes: {
      'http.method': req.method,
      'http.url': req.url,
      'http.user_agent': req.get('User-Agent'),
    }
  });
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    span.setAttributes({
      'http.status_code': res.statusCode,
      'http.response_size': res.get('Content-Length'),
    });
    
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      traceId: span.spanContext().traceId,
      spanId: span.spanContext().spanId,
    });
    
    span.end();
  });
  
  next();
};
```

### Para aplicações Python com OpenTelemetry

#### 1. Instalar dependências
```bash
pip install opentelemetry-api opentelemetry-sdk opentelemetry-instrumentation-flask opentelemetry-exporter-otlp-proto-http python-json-logger elasticsearch
```

#### 2. Configurar OpenTelemetry
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor

# Configurar o provider de traces
resource = Resource.create({"service.name": "minha-app", "service.version": "1.0.0"})
trace.set_tracer_provider(TracerProvider(resource=resource))

# Configurar o exportador
otlp_exporter = OTLPSpanExporter(endpoint="http://localhost:4318/v1/traces")
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Instrumentar Flask
FlaskInstrumentor().instrument()
```

## 📊 Visualização de Dados

### Kibana - Logs e Visualização
- **Discover**: Pesquisa e análise de logs
- **Dashboards**: Visualizações customizadas
- **Index Patterns**: Configuração de índices
- **Alertas**: Configuração de alertas baseados em logs

### Jaeger - Traces e Spans
- **Search**: Busca de traces por serviço, operação, tags
- **Trace View**: Visualização detalhada de traces
- **Dependencies**: Mapa de dependências entre serviços
- **Metrics**: Métricas de latência e throughput

### OpenTelemetry Collector - Métricas
- **Prometheus Endpoint**: `/metrics` para scraping
- **Health Check**: `/health` para monitoramento
- **Configuration**: Pipeline de processamento
- **Exporters**: Configuração de destinos

## 🔒 Segurança

- **Autenticação**: Credenciais configuráveis
- **TLS/SSL**: Suporte a HTTPS
- **Filtros**: Remoção automática de dados sensíveis
- **Isolamento**: Rede Docker isolada
- **Backup**: Backup automático dos dados

## 📈 Escalabilidade

O sistema foi projetado para:
- **Aplicações**: Suportar até 100 aplicações simultâneas
- **Logs**: Processar 50.000 logs por minuto
- **Traces**: Rastrear 10.000 traces por minuto
- **Métricas**: Coletar 1.000 métricas por segundo
- **Armazenamento**: 90 dias de retenção configurável
- **Backup**: Backup automático diário

## 🛠️ Manutenção

### Backup
```bash
# Backup do Elasticsearch
docker exec gwan-elasticsearch elasticsearch-dump --input=http://localhost:9200/gwan-logs --output=backup-logs.json

# Backup das configurações
docker cp gwan-otel-collector:/etc/otel-collector-config.yaml ./backup/otel-config.yaml
```

### Limpeza de Dados Antigos
Configure políticas de retenção:
- **Logs**: 30-90 dias (configurável)
- **Traces**: 7-30 dias (configurável)
- **Métricas**: 90-365 dias (configurável)

### Monitoramento do Sistema
- **CPU**: < 80% por container
- **Memória**: < 85% por container
- **Disco**: < 90% total
- **Rede**: < 1Gbps por serviço

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. OpenTelemetry Collector não inicia
```bash
# Verificar logs
docker logs gwan-otel-collector

# Verificar configuração
docker exec gwan-otel-collector cat /etc/otel-collector-config.yaml

# Verificar conectividade
curl http://localhost:4318/health
```

#### 2. Traces não aparecem no Jaeger
```bash
# Verificar se o Collector está recebendo dados
curl http://localhost:4318/v1/traces

# Verificar conectividade com Jaeger
curl http://jaeger:16686/api/services

# Verificar configuração OTLP
docker logs gwan-jaeger
```

#### 3. Métricas não são coletadas
```bash
# Verificar endpoint de métricas
curl http://localhost:8888/metrics

# Verificar configuração do Prometheus
docker logs gwan-otel-collector | grep prometheus

# Verificar conectividade da aplicação
telnet localhost 4318
```

#### 4. Logs não aparecem no Kibana
```bash
# Verificar Elasticsearch
curl http://localhost:9200/_cluster/health

# Verificar Logstash
docker logs gwan-logstash

# Verificar índices
curl http://localhost:9200/_cat/indices
```

### Logs do Sistema
```bash
# Logs do OpenTelemetry Collector
docker logs gwan-otel-collector

# Logs do Jaeger
docker logs gwan-jaeger

# Logs do Elasticsearch
docker logs gwan-elasticsearch

# Logs do Logstash
docker logs gwan-logstash

# Logs do Kibana
docker logs gwan-kibana
```

## 📞 Suporte

Para suporte técnico:
- **GitHub Issues**: [Abrir Issue](link-para-issues)
- **Email**: suporte@gwan.com.br
- **Documentação**: [Wiki do Projeto](link-para-wiki)
- **Telegram**: @gwan_suporte

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Desenvolvido para Gwan.com.br** 🚀
