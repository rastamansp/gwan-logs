# Exemplo Node.js - Teste de Logs com OpenTelemetry

Este exemplo demonstra como enviar logs, métricas e traces de uma aplicação Node.js para o stack ELK + OpenTelemetry.

## Pré-requisitos

1. Stack ELK + OpenTelemetry rodando (Elasticsearch, Logstash, Kibana, OpenTelemetry Collector, Jaeger)
2. Node.js 16+ instalado
3. Porta 5044 do Logstash acessível
4. Porta 4318 do OpenTelemetry Collector acessível

## Como usar

### 1. Verificar se o stack está rodando

```bash
docker-compose ps
```

Certifique-se de que todos os serviços estão com status "Up".

### 2. Instalar dependências

```bash
cd examples/nodejs
npm install
```

### 3. Executar a aplicação de teste

```bash
npm start
```

### 4. Verificar os dados nos diferentes sistemas

#### Logs (Kibana)
1. Acesse: `http://localhost:5601` ou `http://kibana.gwan.com.br`
2. Vá em **Discover**
3. Selecione o índice `gwan-logs-*`
4. Configure o filtro de tempo para "Last 15 minutes"
5. Procure por logs com `service: "gwan-app"`

#### Traces (Jaeger)
1. Acesse: `http://localhost:16686` ou `http://jaeger.gwan.com.br`
2. Selecione o serviço `gwan-app`
3. Visualize traces distribuídos
4. Analise latência e dependências

#### Métricas (OpenTelemetry Collector)
1. Acesse: `http://localhost:8888/metrics`
2. Visualize métricas em tempo real
3. Procure por métricas como `requests_total`, `request_duration`, `errors_total`

## Estrutura dos Dados

### Logs
```json
{
  "@timestamp": "2024-01-15 10:30:00",
  "level": "INFO",
  "message": "HTTP Request",
  "service": "gwan-app",
  "environment": "production",
  "hostname": "seu-hostname",
  "pid": 1234,
  "method": "GET",
  "url": "/",
  "status": 200,
  "duration": "45ms",
  "traceId": "abc123...",
  "spanId": "def456..."
}
```

### Traces
- Rastreamento automático de requisições HTTP
- Spans para operações específicas
- Contexto distribuído entre serviços
- Integração com logs via traceId/spanId

### Métricas
- `requests_total`: Contador de requisições por método/path/status
- `request_duration`: Histograma de duração das requisições
- `errors_total`: Contador de erros por tipo

## Funcionalidades OpenTelemetry

### Auto-instrumentação
- Express.js automaticamente instrumentado
- Métricas de sistema coletadas
- Traces distribuídos

### Métricas Customizadas
- Contador de requisições
- Histograma de duração
- Contador de erros

### Logs Estruturados
- Integração com Winston
- TraceId e SpanId nos logs
- Formato JSON padronizado

## Personalização

Para personalizar a telemetria, edite o arquivo `logger.js`:

1. Modifique as métricas no `meter.createCounter()` e `meter.createHistogram()`
2. Ajuste os atributos dos spans
3. Personalize o formato dos logs
4. Configure filtros de dados sensíveis

## Troubleshooting

### OpenTelemetry Collector não inicia
```bash
docker logs gwan-otel-collector
```

### Traces não aparecem no Jaeger
1. Verifique se o Collector está rodando
2. Confirme se a aplicação está enviando dados para porta 4318
3. Verifique a configuração OTLP

### Logs não aparecem no Kibana
1. Verifique se o Logstash está rodando
2. Confirme se o Elasticsearch está saudável
3. Verifique os logs do Logstash

### Métricas não são coletadas
1. Verifique se a aplicação está enviando métricas
2. Confirme se o endpoint OTLP está acessível
3. Verifique os logs do Collector

## Variáveis de Ambiente

```bash
# OpenTelemetry
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
NODE_ENV=production
APP_VERSION=1.0.0

# Elasticsearch
ELASTICSEARCH_URL=http://elasticsearch:9200
ELASTIC_USERNAME=elastic
ELASTIC_PASSWORD=pazdeDeus@2025

# Logs
LOG_LEVEL=info
```

## Próximos Passos

- Configurar alertas baseados em métricas
- Criar dashboards no Kibana
- Implementar sampling para alta carga
- Adicionar instrumentação para banco de dados
- Configurar backup dos dados de telemetria
- Implementar correlação entre logs, traces e métricas
