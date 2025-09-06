# 🌐 URLs do Sistema APM Gwan Logs

## 📋 Visão Geral
Este documento contém todas as URLs disponíveis para acessar os serviços do sistema de logs e APM (Application Performance Monitoring) da Gwan.

---

## ✅ URLs Principais (via Traefik)

### 🔍 Jaeger - Visualização de Traces
- **Interface Web**: [http://jaeger.gwan.com.br/](http://jaeger.gwan.com.br/)
- **Página de Busca**: [http://jaeger.gwan.com.br/search](http://jaeger.gwan.com.br/search)

### 📊 Kibana - Visualização de Logs
- **Interface Web**: [http://kibana.gwan.com.br/](http://kibana.gwan.com.br/)
- **Dashboards**: [http://kibana.gwan.com.br/app/dashboards](http://kibana.gwan.com.br/app/dashboards)
- **Discover**: [http://kibana.gwan.com.br/app/discover](http://kibana.gwan.com.br/app/discover)

### 📈 Prometheus - Monitoramento
- **Interface Web**: [http://prometheus.gwan.com.br/](http://prometheus.gwan.com.br/)
- **Targets**: [http://prometheus.gwan.com.br/targets](http://prometheus.gwan.com.br/targets)
- **Graph**: [http://prometheus.gwan.com.br/graph](http://prometheus.gwan.com.br/graph)

### 🚨 Alertmanager - Alertas
- **Interface Web**: [http://alertmanager.gwan.com.br/](http://alertmanager.gwan.com.br/)
- **Alertas**: [http://alertmanager.gwan.com.br/#/alerts](http://alertmanager.gwan.com.br/#/alerts)

---

## 🔧 URLs de Acesso Direto (portas)

### 🔍 Jaeger
- **Interface Web**: [http://gwan.com.br:16687/](http://gwan.com.br:16687/)
- **Página de Busca**: [http://gwan.com.br:16687/search](http://gwan.com.br:16687/search)

### 📊 Kibana
- **Interface Web**: [http://gwan.com.br:5602/](http://gwan.com.br:5602/)

### 📈 Prometheus
- **Interface Web**: [http://gwan.com.br:9091/](http://gwan.com.br:9091/)

### 🚨 Alertmanager
- **Interface Web**: [http://gwan.com.br:9094/](http://gwan.com.br:9094/)

### 📡 OpenTelemetry Collector
- **OTLP gRPC**: `http://gwan.com.br:4317`
- **OTLP HTTP**: `http://gwan.com.br:4318`

---

## 🎯 Checklist de Testes

### ✅ Testes Básicos
- [ ] Jaeger - Interface de traces funcionando
- [ ] Kibana - Interface de logs funcionando  
- [ ] Prometheus - Métricas sendo coletadas
- [ ] Alertmanager - Sistema de alertas ativo

### ✅ Testes de Funcionalidades
- [ ] Jaeger - Busca de traces funcionando
- [ ] Kibana - Dashboards carregando
- [ ] Prometheus - Targets sendo monitorados
- [ ] Alertmanager - Alertas sendo processados

### ✅ Testes de Conectividade
- [ ] OTEL Collector - Recebendo telemetria
- [ ] Traefik - Roteamento funcionando corretamente
- [ ] Acesso via domínios (Traefik)
- [ ] Acesso via portas diretas (fallback)

---

## 📝 Notas Importantes

- **Prioridade**: Teste primeiro as URLs via Traefik (domínios), depois as URLs diretas (portas) como fallback
- **Rede**: Certifique-se de que os domínios estão configurados no DNS
- **Firewall**: Verifique se as portas estão abertas no firewall
- **SSL**: Para produção, configure certificados SSL/TLS

---

## 🔗 Links Úteis

- **Documentação**: [README.md](./README.md)
- **Deploy**: [docs/deployment.md](./docs/deployment.md)
- **Troubleshooting**: [docs/troubleshooting.md](./docs/troubleshooting.md)
- **Verificação de Telemetria**: [docs/telemetry-verification.md](./docs/telemetry-verification.md)

## 🧪 Scripts de Teste

### **Verificação Automática de Telemetria**
```bash
# Linux/Mac
./scripts/check-telemetry.sh

# Windows PowerShell
.\scripts\check-telemetry.ps1
```

### **Teste Manual de Envio**
```bash
# Teste de trace
curl -X POST http://gwan.com.br:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"test-service"}}]},"scopeSpans":[{"scope":{"name":"test-scope"},"spans":[{"traceId":"12345678901234567890123456789012","spanId":"1234567890123456","name":"test-span","kind":"SPAN_KIND_INTERNAL","startTimeUnixNano":"1640995200000000000","endTimeUnixNano":"1640995201000000000"}]}]}]}'

# Teste de log
curl -X POST http://gwan.com.br:4318/v1/logs \
  -H "Content-Type: application/json" \
  -d '{"resourceLogs":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"test-service"}}]},"scopeLogs":[{"scope":{"name":"test-scope"},"logRecords":[{"timeUnixNano":"1640995200000000000","severityNumber":9,"severityText":"INFO","body":{"stringValue":"Test log message"}}]}]}]}'
```