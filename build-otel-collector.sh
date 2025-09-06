#!/bin/bash

# Script para construir imagem customizada do OTEL Collector
echo "Construindo imagem customizada do OpenTelemetry Collector..."

# Verificar se o arquivo de configuração existe
if [ ! -f "configs/otel-collector/otel-collector-config.yaml" ]; then
    echo "ERRO: Arquivo de configuração não encontrado!"
    echo "Criando arquivo de configuração padrão..."
    
    mkdir -p configs/otel-collector
    
    cat > configs/otel-collector/otel-collector-config.yaml << 'EOF'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 10s
          static_configs:
            - targets: ['localhost:8888']

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024

  memory_limiter:
    limit_mib: 256
    spike_limit_mib: 128

exporters:
  debug:
    verbosity: detailed

  otlp:
    endpoint: jaeger:14250
    tls:
      insecure: true

  prometheus:
    endpoint: '0.0.0.0:8889'

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug, otlp]

    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [debug, prometheus]

    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug]

  extensions: [health_check]
  telemetry:
    logs:
      level: info

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
EOF
fi

# Construir a imagem
docker build -f Dockerfile.otel-collector -t gwan-otel-collector:latest .

echo "Imagem construída com sucesso: gwan-otel-collector:latest"
echo "Agora você pode usar esta imagem no docker-compose.production.yml"
