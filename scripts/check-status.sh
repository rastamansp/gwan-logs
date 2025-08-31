#!/bin/bash

# Script para verificar status do ELK Stack
echo "🔍 Verificando status do Gwan Logs ELK Stack..."
echo "================================================"

# Verificar containers
echo "📦 Status dos Containers:"
docker ps --filter "name=gwan-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔧 Verificando Elasticsearch:"
if curl -s -u elastic:${ELASTIC_PASSWORD:-GwanLogs2024!} http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "✅ Elasticsearch está respondendo"
    echo "📊 Health do Cluster:"
    curl -s -u elastic:${ELASTIC_PASSWORD:-GwanLogs2024!} http://localhost:9200/_cluster/health | jq .
else
    echo "❌ Elasticsearch não está respondendo"
fi

echo ""
echo "🎨 Verificando Kibana:"
if curl -s http://localhost:5601/api/status > /dev/null 2>&1; then
    echo "✅ Kibana está respondendo"
    echo "📊 Status do Kibana:"
    curl -s http://localhost:5601/api/status | jq .
else
    echo "❌ Kibana não está respondendo"
fi

echo ""
echo "📋 Logs dos Containers:"
echo "Elasticsearch logs (últimas 10 linhas):"
docker logs --tail 10 gwan-elasticsearch 2>/dev/null || echo "Container não encontrado"

echo ""
echo "Kibana logs (últimas 10 linhas):"
docker logs --tail 10 gwan-kibana 2>/dev/null || echo "Container não encontrado"

echo ""
echo "🎯 URLs de Acesso:"
echo "Kibana: https://logs.gwan.com.br"
echo "Elasticsearch: http://localhost:9200 (interno)"
echo "Credenciais: elastic / ${ELASTIC_PASSWORD:-GwanLogs2024!}"
