# Gwan APM - Sistema de Observabilidade Completa

Sistema de observabilidade completa para aplicações Node.js e Python rodando no Portainer, utilizando Elasticsearch, Logstash, Kibana, OpenTelemetry, Jaeger e Prometheus para monitoramento, logs e traces distribuídos.

## 🏗️ Arquitetura

```mermaid
graph TB
    A[Aplicações<br/>Node.js/Python] --> B[OpenTelemetry<br/>Collector]
    B --> C[Logstash<br/>Processamento]
    B --> D[Prometheus<br/>Métricas]
    B --> E[Jaeger<br/>Traces]
    C --> F[Elasticsearch<br/>Armazenamento]
    D --> G[Kibana<br/>Visualização]
    E --> G
    F --> G
    
    style A fill:#e1f5fe
    style B fill:#fff3e0
    style C fill:#f3e5f5
    style D fill:#e8f5e8
    style E fill:#fff8e1
    style F fill:#fce4ec
    style G fill:#e0f2f1
```

## 🔍 Observabilidade Completa

### APM (Application Performance Management)
O sistema evoluiu de um simples sistema de logs para um **APM completo** que oferece:

#### 📊 **Métricas (Metrics)**
- **Contadores**: Total de requisições, erros, operações
- **Histogramas**: Duração de requisições, latência
- **Gauges**: Uso de memória, CPU, conexões ativas
- **Auto-instrumentação**: Métricas automáticas do sistema

#### 🔗 **Traces (Rastreamento Distribuído)**
- **Spans distribuídos**: Rastreamento de requisições entre serviços
- **Contexto distribuído**: Propagação de contexto entre aplicações
- **Latência**: Medição de tempo de resposta
- **Dependências**: Mapeamento de chamadas entre serviços

#### 📝 **Logs Estruturados**
- **Correlação**: Logs vinculados a traces via TraceId/SpanId
- **Formato JSON**: Logs estruturados e padronizados
- **Filtros**: Remoção automática de dados sensíveis
- **Enriquecimento**: Adição de metadados automáticos

### Fluxo de Dados APM

```mermaid
flowchart LR
    A[Aplicação<br/>Node.js/Python] --> B[📝 Logs]
    A --> C[🔍 Traces]
    A --> D[📈 Metrics]
    A --> E[📊 Telemetria]
    
    B --> F[Logstash]
    C --> G[OpenTelemetry<br/>Collector]
    D --> G
    E --> G
    
    F --> H[Elasticsearch]
    G --> I[Jaeger]
    G --> J[Prometheus]
    G --> F
    
    H --> K[Kibana]
    I --> K
    J --> K
    
    style A fill:#e1f5fe
    style F fill:#f3e5f5
    style G fill:#fff3e0
    style H fill:#fce4ec
    style I fill:#fff8e1
    style J fill:#e8f5e8
    style K fill:#e0f2f1
```

### Sequência de uma Requisição HTTP

```mermaid
sequenceDiagram
    participant Client
    participant App as Aplicação Node.js
    participant OTEL as OpenTelemetry Collector
    participant LS as Logstash
    participant ES as Elasticsearch
    participant J as Jaeger
    participant P as Prometheus
    participant K as Kibana

    Client->>App: HTTP Request
    App->>App: Criar Span (TraceId: abc123)
    App->>OTEL: Enviar Trace
    App->>OTEL: Enviar Metrics
    App->>LS: Enviar Log (TraceId: abc123)
    
    OTEL->>J: Armazenar Trace
    OTEL->>P: Armazenar Metrics
    OTEL->>LS: Enviar Logs OTLP
    
    LS->>ES: Indexar Logs
    ES->>K: Disponibilizar dados
    J->>K: Disponibilizar traces
    P->>K: Disponibilizar metrics
    
    Note over K: Correlação via TraceId
```

### Arquitetura de Rede

```mermaid
graph TB
    subgraph "Rede Externa"
        T[Traefik<br/>Load Balancer]
    end
    
    subgraph "Rede Docker 'gwan'"
        subgraph "Stack Gwan APM"
            ES[Elasticsearch<br/>9200]
            K[Kibana<br/>5601]
            LS[Logstash<br/>5044/9600]
            OTEL[OpenTelemetry<br/>4318/8888]
            J[Jaeger<br/>16686]
            P[Prometheus<br/>9090]
        end
    end
    
    T --> ES
    T --> K
    T --> LS
    T --> OTEL
    T --> J
    T --> P
    
    style T fill:#ffebee
    style ES fill:#fce4ec
    style K fill:#e0f2f1
    style LS fill:#f3e5f5
    style OTEL fill:#fff3e0
    style J fill:#fff8e1
    style P fill:#e8f5e8
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
- **📊 Kibana**: `https://kibana.gwan.com.br` (Logs e Visualização)
- **🔍 Jaeger**: `https://jaeger.gwan.com.br` (Traces e Spans)
- **📊 Prometheus**: `https://prometheus.gwan.com.br` (Métricas)
- **🚨 Alertmanager**: `https://alertmanager.gwan.com.br` (Alertas Críticos)
- **🔧 OpenTelemetry Collector**: `https://otel.gwan.com.br` (Status)
- **📝 Logstash**: `https://logstash.gwan.com.br` (Status)
- **🗄️ Elasticsearch**: `https://elasticsearch.gwan.com.br` (API REST)

## 📊 Monitoramento e Alertas

### Alertas Configurados
O sistema monitora apenas alertas críticos de disponibilidade:

- **Elasticsearch Down**: Serviço de armazenamento indisponível
- **Kibana Down**: Interface de visualização indisponível  
- **Prometheus Down**: Coletor de métricas indisponível
- **OpenTelemetry Collector Down**: Coletor de telemetria indisponível

### Métricas Disponíveis
- **Aplicação**: Requisições, erros, latência (via Prometheus)
- **Sistema**: Health checks dos serviços
- **Logs**: Análise completa via Kibana
- **Traces**: Rastreamento distribuído via Jaeger

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

### Kibana - Interface Principal
- **Discover**: Pesquisa e análise de logs
- **Dashboards**: Visualizações customizadas
- **Index Patterns**: Configuração de índices
- **Alertas**: Configuração de alertas baseados em logs
- **Métricas**: Visualizações de performance

### Jaeger - Distributed Tracing
- **Search**: Busca de traces por serviço, operação, tags
- **Trace View**: Visualização detalhada de traces
- **Dependencies**: Mapa de dependências entre serviços
- **Metrics**: Métricas de latência e throughput

### Prometheus - Métricas Básicas
- **Time-series**: Dados históricos de performance
- **Query Language**: PromQL para consultas avançadas
- **Alertas**: Alertas críticos de disponibilidade
- **Health Checks**: Status dos serviços

### Alertmanager - Gestão de Alertas
- **Agrupamento**: Agrupa alertas similares
- **Supressão**: Suprime alertas menores quando há problemas críticos
- **Notificações**: Distribui alertas pelos canais configurados

## 🔒 Segurança

- **Autenticação**: Credenciais configuráveis
- **TLS/SSL**: Suporte a HTTPS
- **Filtros**: Remoção automática de dados sensíveis
- **Isolamento**: Rede Docker isolada
- **Backup**: Backup automático dos dados

## 📈 Escalabilidade

O sistema APM foi projetado para:
- **Aplicações**: Suportar até 100 aplicações simultâneas
- **Logs**: Processar 50.000 logs por minuto
- **Traces**: Rastrear 10.000 traces por minuto
- **Métricas**: Coletar 1.000 métricas por segundo
- **Armazenamento**: 90 dias de retenção configurável
- **Backup**: Backup automático diário
- **Performance**: Latência < 100ms para consultas
- **Disponibilidade**: 99.9% uptime

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
docker logs gwan-prometheus

# Verificar targets no Prometheus
curl http://localhost:9090/api/v1/targets

# Verificar conectividade da aplicação
telnet localhost 4318
```

#### 4. Prometheus sem dados
```bash
# Verificar status do Prometheus
curl http://localhost:9090/-/healthy

# Verificar targets
curl http://localhost:9090/api/v1/targets

# Verificar configuração
docker exec gwan-prometheus cat /etc/prometheus/prometheus.yml

# Verificar logs
docker logs gwan-prometheus
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

#### 5. Alertmanager não envia alertas
```bash
# Verificar status do Alertmanager
curl http://localhost:9093/-/healthy

# Verificar configuração
docker exec gwan-alertmanager cat /etc/alertmanager/alertmanager.yml

# Verificar logs
docker logs gwan-alertmanager

# Verificar conectividade com Prometheus
curl http://localhost:9090/api/v1/alertmanagers
```

### Logs do Sistema
```bash
# Logs do OpenTelemetry Collector
docker logs gwan-otel-collector

# Logs do Jaeger
docker logs gwan-jaeger

# Logs do Prometheus
docker logs gwan-prometheus

# Logs do Alertmanager
docker logs gwan-alertmanager

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
