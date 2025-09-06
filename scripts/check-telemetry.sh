#!/bin/bash

# 🔍 Script de Verificação de Telemetria - Gwan APM
# Este script verifica se a telemetria está sendo recebida corretamente

echo "🚀 Iniciando verificação de telemetria do Gwan APM..."
echo "=================================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para verificar se um serviço está respondendo
check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "🔍 Verificando $service_name... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FALHOU${NC}"
        return 1
    fi
}

# Função para verificar métricas
check_metrics() {
    local metric_name=$1
    local description=$2
    
    echo -n "📊 Verificando $description... "
    
    local value=$(curl -s http://gwan.com.br:8888/metrics | grep "$metric_name" | head -1 | awk '{print $2}')
    
    if [ -n "$value" ] && [ "$value" != "0" ]; then
        echo -e "${GREEN}✅ OK (valor: $value)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Sem dados (valor: $value)${NC}"
        return 1
    fi
}

echo ""
echo "🔧 1. Verificação de Serviços"
echo "=============================="

# Verificar serviços principais
check_service "OTEL Collector Health" "http://gwan.com.br:13133/"
check_service "Jaeger" "http://gwan.com.br:16687/"
check_service "Kibana" "http://gwan.com.br:5602/"
check_service "Prometheus" "http://gwan.com.br:9091/"
check_service "Alertmanager" "http://gwan.com.br:9094/"

echo ""
echo "📊 2. Verificação de Métricas"
echo "============================"

# Verificar métricas do OTEL Collector
check_metrics "otelcol_receiver_accepted_spans_total" "Traces recebidos"
check_metrics "otelcol_receiver_accepted_log_records_total" "Logs recebidos"
check_metrics "otelcol_receiver_accepted_metric_points_total" "Métricas recebidas"

echo ""
echo "🧪 3. Teste de Envio de Telemetria"
echo "=================================="

echo -n "📤 Enviando trace de teste... "

# Enviar trace de teste
TRACE_RESPONSE=$(curl -s -w "%{http_code}" -X POST http://gwan.com.br:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service-script"}
        }]
      },
      "scopeSpans": [{
        "scope": {"name": "test-scope"},
        "spans": [{
          "traceId": "12345678901234567890123456789012",
          "spanId": "1234567890123456",
          "name": "test-span-script",
          "kind": "SPAN_KIND_INTERNAL",
          "startTimeUnixNano": "1640995200000000000",
          "endTimeUnixNano": "1640995201000000000"
        }]
      }]
    }]
  }')

if echo "$TRACE_RESPONSE" | grep -q "200"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FALHOU${NC}"
fi

echo -n "📤 Enviando log de teste... "

# Enviar log de teste
LOG_RESPONSE=$(curl -s -w "%{http_code}" -X POST http://gwan.com.br:4318/v1/logs \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service-script"}
        }]
      },
      "scopeLogs": [{
        "scope": {"name": "test-scope"},
        "logRecords": [{
          "timeUnixNano": "1640995200000000000",
          "severityNumber": 9,
          "severityText": "INFO",
          "body": {"stringValue": "Test log message from script"}
        }]
      }]
    }]
  }')

if echo "$LOG_RESPONSE" | grep -q "200"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FALHOU${NC}"
fi

echo ""
echo "⏳ Aguardando 5 segundos para processamento..."
sleep 5

echo ""
echo "🔍 4. Verificação Pós-Teste"
echo "==========================="

# Verificar se os dados de teste chegaram
check_metrics "otelcol_receiver_accepted_spans_total" "Traces recebidos (pós-teste)"
check_metrics "otelcol_receiver_accepted_log_records_total" "Logs recebidos (pós-teste)"

echo ""
echo "📋 5. URLs para Verificação Manual"
echo "==================================="

echo -e "${BLUE}🔍 Jaeger:${NC} http://jaeger.gwan.com.br/ ou http://gwan.com.br:16687/"
echo -e "${BLUE}📊 Kibana:${NC} http://kibana.gwan.com.br/ ou http://gwan.com.br:5602/"
echo -e "${BLUE}📈 Prometheus:${NC} http://prometheus.gwan.com.br/ ou http://gwan.com.br:9091/"
echo -e "${BLUE}🚨 Alertmanager:${NC} http://alertmanager.gwan.com.br/ ou http://gwan.com.br:9094/"

echo ""
echo "💡 Dicas:"
echo "=========="
echo "• Procure por 'test-service-script' no Jaeger"
echo "• Procure por 'test-service-script' no Kibana Discover"
echo "• Verifique as métricas no Prometheus"
echo "• Consulte os logs dos containers se houver problemas"

echo ""
echo "✅ Verificação concluída!"
echo "========================"
