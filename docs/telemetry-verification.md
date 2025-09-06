# 🔍 Guia de Verificação de Telemetria - Gwan APM

Este guia mostra como verificar se a telemetria está sendo recebida corretamente pelo sistema APM.

---

## 🚀 Verificação Rápida (5 minutos)

### 1. **Verificar Status dos Containers**
```bash
# No Portainer ou via Docker
docker ps | grep gwan
```

**Containers que devem estar rodando:**
- `gwan-otel-collector` ✅
- `gwan-jaeger` ✅
- `gwan-elasticsearch` ✅
- `gwan-kibana` ✅
- `gwan-prometheus` ✅

### 2. **Verificar Logs do OTEL Collector**
```bash
# No Portainer: Containers > gwan-otel-collector > Logs
# Ou via Docker:
docker logs gwan-otel-collector --tail 50
```

**Logs esperados:**
```
info	service@v0.88.0/telemetry.go:84	Setting up own telemetry...
info	service@v0.88.0/telemetry.go:201	Serving Prometheus metrics	{"address": ":8888", "level": "Basic"}
info	exporter@v0.88.0/exporter.go:275	Development component. May change in the future.	{"kind": "exporter", "data_type": "traces", "name": "debug"}
info	exporter@v0.88.0/exporter.go:275	Development component. May change in the future.	{"kind": "exporter", "data_type": "logs", "name": "debug"}
info	service@v0.88.0/service.go:169	Everything is ready. Begin running and processing data.
```

---

## 🔧 Verificação Detalhada

### 1. **Health Check do OTEL Collector**
```bash
# Verificar se o collector está saudável
curl http://gwan.com.br:13133/
```

**Resposta esperada:**
```json
{
  "status": "Server available",
  "uptime": "1h23m45s",
  "pid": 1
}
```

### 2. **Métricas do OTEL Collector**
```bash
# Verificar métricas internas do collector
curl http://gwan.com.br:8888/metrics | grep otelcol
```

**Métricas importantes:**
- `otelcol_receiver_accepted_spans_total` - Traces recebidos
- `otelcol_receiver_accepted_log_records_total` - Logs recebidos
- `otelcol_receiver_accepted_metric_points_total` - Métricas recebidas

### 3. **Verificar Jaeger**
```bash
# Acessar interface do Jaeger
# http://jaeger.gwan.com.br/ ou http://gwan.com.br:16687/
```

**O que verificar:**
- [ ] Interface carrega sem erros
- [ ] Serviços aparecem na lista (quando traces são enviados)
- [ ] Busca funciona corretamente

### 4. **Verificar Kibana**
```bash
# Acessar interface do Kibana
# http://kibana.gwan.com.br/ ou http://gwan.com.br:5602/
```

**O que verificar:**
- [ ] Interface carrega sem erros
- [ ] Índices aparecem no Management > Index Patterns
- [ ] Discover mostra logs (quando logs são enviados)

---

## 🧪 Teste Prático de Envio de Telemetria

### 1. **Teste com cURL (Traces)**
```bash
# Enviar trace de teste para o OTEL Collector
curl -X POST http://gwan.com.br:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeSpans": [{
        "scope": {"name": "test-scope"},
        "spans": [{
          "traceId": "12345678901234567890123456789012",
          "spanId": "1234567890123456",
          "name": "test-span",
          "kind": "SPAN_KIND_INTERNAL",
          "startTimeUnixNano": "1640995200000000000",
          "endTimeUnixNano": "1640995201000000000"
        }]
      }]
    }]
  }'
```

### 2. **Teste com cURL (Logs)**
```bash
# Enviar log de teste para o OTEL Collector
curl -X POST http://gwan.com.br:4318/v1/logs \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeLogs": [{
        "scope": {"name": "test-scope"},
        "logRecords": [{
          "timeUnixNano": "1640995200000000000",
          "severityNumber": 9,
          "severityText": "INFO",
          "body": {"stringValue": "Test log message"}
        }]
      }]
    }]
  }'
```

### 3. **Verificar se os dados chegaram**

**No Jaeger:**
1. Acesse http://jaeger.gwan.com.br/
2. Procure por "test-service" na lista de serviços
3. Clique em "Find Traces"

**No Kibana:**
1. Acesse http://kibana.gwan.com.br/
2. Vá em Discover
3. Procure por logs com `service.name: "test-service"`

---

## 🔍 Verificação de Aplicação Real

### 1. **Configurar sua aplicação backend**

**Node.js:**
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  serviceName: 'minha-aplicacao-backend',
  instrumentations: [getNodeAutoInstrumentations()],
  traceExporter: {
    url: 'http://gwan.com.br:4318/v1/traces'
  },
  logExporter: {
    url: 'http://gwan.com.br:4318/v1/logs'
  }
});

sdk.start();
```

**Python:**
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configurar tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configurar exportador
otlp_exporter = OTLPSpanExporter(endpoint="http://gwan.com.br:4317")
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Usar o tracer
with tracer.start_as_current_span("minha-operacao"):
    # Seu código aqui
    pass
```

### 2. **Verificar métricas de recebimento**

```bash
# Verificar quantos traces foram recebidos
curl -s http://gwan.com.br:8888/metrics | grep otelcol_receiver_accepted_spans_total

# Verificar quantos logs foram recebidos
curl -s http://gwan.com.br:8888/metrics | grep otelcol_receiver_accepted_log_records_total
```

---

## 🚨 Troubleshooting

### **Problema: OTEL Collector não recebe dados**

**Verificações:**
1. Container está rodando? `docker ps | grep otel-collector`
2. Portas estão abertas? `netstat -tulpn | grep 4317`
3. Logs mostram erros? `docker logs gwan-otel-collector`

**Soluções:**
- Verificar configuração de rede Docker
- Verificar se as portas estão expostas
- Verificar logs do collector para erros

### **Problema: Jaeger não mostra traces**

**Verificações:**
1. Jaeger está rodando? `docker ps | grep jaeger`
2. OTEL Collector está enviando para Jaeger?
3. Configuração do exporter está correta?

**Soluções:**
- Verificar configuração do exporter no OTEL Collector
- Verificar conectividade entre containers
- Verificar logs do Jaeger

### **Problema: Kibana não mostra logs**

**Verificações:**
1. Elasticsearch está rodando? `docker ps | grep elasticsearch`
2. Índices foram criados? Verificar no Kibana > Management
3. OTEL Collector está enviando logs para Elasticsearch?

**Soluções:**
- Verificar configuração do exporter para Elasticsearch
- Verificar conectividade com Elasticsearch
- Verificar logs do Elasticsearch

---

## 📊 Monitoramento Contínuo

### **Dashboard de Métricas**
Acesse http://prometheus.gwan.com.br/ e configure alertas para:

- `otelcol_receiver_accepted_spans_total` - Quantidade de traces recebidos
- `otelcol_receiver_accepted_log_records_total` - Quantidade de logs recebidos
- `otelcol_receiver_refused_spans_total` - Traces rejeitados (deve ser 0)

### **Alertas Recomendados**
```yaml
# No Prometheus
- alert: OTELCollectorDown
  expr: up{job="otel-collector"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "OTEL Collector está fora do ar"

- alert: NoTracesReceived
  expr: rate(otelcol_receiver_accepted_spans_total[5m]) == 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Nenhum trace recebido nos últimos 5 minutos"
```

---

## ✅ Checklist Final

- [ ] OTEL Collector está rodando e saudável
- [ ] Jaeger está acessível e funcionando
- [ ] Kibana está acessível e funcionando
- [ ] Teste de envio de telemetria funcionou
- [ ] Aplicação backend está enviando dados
- [ ] Traces aparecem no Jaeger
- [ ] Logs aparecem no Kibana
- [ ] Métricas estão sendo coletadas no Prometheus
- [ ] Alertas estão configurados

---

## 📞 Suporte

Se ainda tiver problemas:
1. Verifique os logs de todos os containers
2. Teste a conectividade entre os serviços
3. Verifique a configuração de rede Docker
4. Consulte a documentação de troubleshooting
