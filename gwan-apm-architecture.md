# Arquitetura Detalhada do Sistema Gwan APM

## Diagrama Principal da Arquitetura

```mermaid
graph TB
    subgraph "Aplicações Cliente"
        A1[Aplicação Node.js<br/>Porta 3000]
        A2[Aplicação Python<br/>Porta 8001]
        A3[Outras Aplicações<br/>Diversas Portas]
    end

    subgraph "Rede Externa - Traefik"
        T[Traefik Load Balancer<br/>Portas 80/443/8081/8444]
    end

    subgraph "Rede Docker 'gwan'"
        subgraph "Sistema Gwan APM"
            subgraph "Coleta de Dados"
                OTEL[OpenTelemetry Collector<br/>Portas 4317/4318<br/>Container: gwan-otel-collector]
                LS[Logstash<br/>Portas 5044/5000/5001<br/>Container: gwan-logstash]
            end
            
            subgraph "Armazenamento"
                ES[Elasticsearch<br/>Porta 9200<br/>Container: gwan-elasticsearch]
            end
            
            subgraph "Visualização"
                K[Kibana<br/>Porta 5601<br/>Container: gwan-kibana]
                J[Jaeger<br/>Porta 16686<br/>Container: gwan-jaeger]
                P[Prometheus<br/>Porta 9090<br/>Container: gwan-prometheus]
                AM[Alertmanager<br/>Porta 9093<br/>Container: gwan-alertmanager]
            end
        end
    end

    subgraph "Interfaces Web"
        KIB[Kibana UI<br/>kibana.gwan.com.br:5602]
        JAG[Jaeger UI<br/>jaeger.gwan.com.br:16687]
        PROM[Prometheus UI<br/>prometheus.gwan.com.br:9091]
        ALERT[Alertmanager UI<br/>alertmanager.gwan.com.br:9094]
    end

    %% Fluxo de Dados das Aplicações
    A1 -->|OTLP gRPC/HTTP<br/>Traces + Metrics| OTEL
    A1 -->|Logs TCP/UDP<br/>Porta 5000/5001| LS
    A1 -->|Logs Elasticsearch<br/>Direto| ES
    
    A2 -->|OTLP gRPC/HTTP<br/>Traces + Metrics| OTEL
    A2 -->|Logs TCP/UDP<br/>Porta 5000/5001| LS
    
    A3 -->|OTLP gRPC/HTTP<br/>Traces + Metrics| OTEL
    A3 -->|Logs TCP/UDP<br/>Porta 5000/5001| LS

    %% Processamento de Dados
    OTEL -->|Traces OTLP| J
    OTEL -->|Metrics Prometheus| P
    OTEL -->|Logs OTLP| LS
    
    LS -->|Logs Processados| ES

    %% Rede Externa
    T -->|Proxy HTTP/HTTPS| KIB
    T -->|Proxy HTTP/HTTPS| JAG
    T -->|Proxy HTTP/HTTPS| PROM
    T -->|Proxy HTTP/HTTPS| ALERT

    %% Conexões Internas
    KIB -.->|Consulta Dados| ES
    JAG -.->|Consulta Traces| J
    PROM -.->|Consulta Métricas| P
    ALERT -.->|Recebe Alertas| P

    %% Estilos
    style A1 fill:#e1f5fe
    style A2 fill:#e1f5fe
    style A3 fill:#e1f5fe
    style OTEL fill:#fff3e0
    style LS fill:#f3e5f5
    style ES fill:#fce4ec
    style K fill:#e0f2f1
    style J fill:#fff8e1
    style P fill:#e8f5e8
    style AM fill:#fff3e0
    style T fill:#ffebee
```

## Fluxo Detalhado de Dados APM

```mermaid
flowchart LR
    subgraph "Aplicação Node.js/Python"
        APP[Aplicação]
        OTEL_SDK[OpenTelemetry SDK]
        LOGGER[Winston Logger]
    end

    subgraph "Coleta"
        OTEL_COL[OpenTelemetry Collector<br/>4317/4318]
        LOGSTASH[Logstash<br/>5044/5000/5001]
    end

    subgraph "Armazenamento"
        ELASTIC[Elasticsearch<br/>9200]
        JAEGER[Jaeger<br/>16686]
        PROM[Prometheus<br/>9090]
    end

    subgraph "Visualização"
        KIBANA[Kibana<br/>5601]
        JAEGER_UI[Jaeger UI<br/>16686]
        PROM_UI[Prometheus UI<br/>9090]
    end

    %% Fluxo de Traces
    APP -->|Instrumentação Automática| OTEL_SDK
    OTEL_SDK -->|OTLP gRPC/HTTP| OTEL_COL
    OTEL_COL -->|Traces| JAEGER
    JAEGER -->|Consulta| JAEGER_UI

    %% Fluxo de Métricas
    OTEL_SDK -->|Métricas| OTEL_COL
    OTEL_COL -->|Prometheus Format| PROM
    PROM -->|Consulta| PROM_UI

    %% Fluxo de Logs
    APP -->|Logs Estruturados| LOGGER
    LOGGER -->|TCP/UDP| LOGSTASH
    LOGGER -->|Elasticsearch Direct| ELASTIC
    OTEL_COL -->|Logs OTLP| LOGSTASH
    LOGSTASH -->|Processamento| ELASTIC
    ELASTIC -->|Consulta| KIBANA

    %% Correlação
    OTEL_SDK -.->|TraceId/SpanId| LOGGER
    LOGGER -.->|TraceId/SpanId| LOGSTASH

    style APP fill:#e1f5fe
    style OTEL_SDK fill:#fff3e0
    style LOGGER fill:#f3e5f5
    style OTEL_COL fill:#fff3e0
    style LOGSTASH fill:#f3e5f5
    style ELASTIC fill:#fce4ec
    style JAEGER fill:#fff8e1
    style PROM fill:#e8f5e8
    style KIBANA fill:#e0f2f1
```

## Sequência de uma Requisição HTTP Completa

```mermaid
sequenceDiagram
    participant Client as Cliente
    participant App as Aplicação Node.js
    participant OTEL as OpenTelemetry Collector
    participant LS as Logstash
    participant ES as Elasticsearch
    participant J as Jaeger
    participant P as Prometheus
    participant K as Kibana

    Client->>App: HTTP Request
    Note over App: Criar Span (TraceId: abc123)
    
    App->>OTEL: Enviar Trace (OTLP)
    App->>OTEL: Enviar Metrics (OTLP)
    App->>LS: Enviar Log (TraceId: abc123)
    App->>ES: Enviar Log Direto (TraceId: abc123)
    
    OTEL->>J: Armazenar Trace
    OTEL->>P: Armazenar Metrics
    OTEL->>LS: Enviar Logs OTLP
    
    LS->>ES: Indexar Logs Processados
    
    Note over ES: Dados Correlacionados via TraceId
    ES->>K: Disponibilizar Logs
    J->>K: Disponibilizar Traces
    P->>K: Disponibilizar Metrics
    
    Client->>K: Consultar Dados APM
    K->>ES: Buscar Logs
    K->>J: Buscar Traces
    K->>P: Buscar Metrics
    
    Note over K: Correlação Completa via TraceId
```

## Arquitetura de Rede e Portas

```mermaid
graph TB
    subgraph "Rede Externa"
        INTERNET[Internet]
        TRAEFIK[Traefik<br/>Load Balancer<br/>Portas 80/443/8081/8444]
    end
    
    subgraph "Rede Docker 'gwan'"
        subgraph "Stack Gwan APM"
            subgraph "Serviços Internos"
                ES[Elasticsearch<br/>9200 - Interno]
                LS_API[Logstash API<br/>9600 - Interno]
                OTEL_METRICS[OTEL Metrics<br/>8888 - Interno]
            end
            
            subgraph "Serviços de Coleta"
                LS[Logstash<br/>5044/5000/5001<br/>Externo para Apps]
                OTEL[OpenTelemetry<br/>4317/4318<br/>Externo para Apps]
            end
            
            subgraph "Serviços de Visualização"
                K[Kibana<br/>5601 → 5602]
                J[Jaeger<br/>16686 → 16687]
                P[Prometheus<br/>9090 → 9091]
                A[Alertmanager<br/>9093 → 9094]
            end
        end
    end

    subgraph "Aplicações Cliente"
        NODE[Node.js Apps<br/>Porta 3000]
        PYTHON[Python Apps<br/>Porta 8001]
        OTHER[Outras Apps<br/>Diversas Portas]
    end

    %% Conexões Externas
    INTERNET --> TRAEFIK
    TRAEFIK -->|kibana.gwan.com.br| K
    TRAEFIK -->|jaeger.gwan.com.br| J
    TRAEFIK -->|prometheus.gwan.com.br| P
    TRAEFIK -->|alertmanager.gwan.com.br| A

    %% Conexões de Aplicações
    NODE -->|Logs TCP/UDP| LS
    NODE -->|Telemetria OTLP| OTEL
    PYTHON -->|Logs TCP/UDP| LS
    PYTHON -->|Telemetria OTLP| OTEL
    OTHER -->|Logs TCP/UDP| LS
    OTHER -->|Telemetria OTLP| OTEL

    %% Conexões Internas
    LS -.->|Logs Processados| ES
    OTEL -.->|Traces| J
    OTEL -.->|Métricas| P
    OTEL -.->|Logs OTLP| LS

    %% Conexões de Visualização
    K -.->|Consulta| ES
    J -.->|Consulta| J
    P -.->|Consulta| P
    A -.->|Recebe| P

    style INTERNET fill:#e3f2fd
    style TRAEFIK fill:#ffebee
    style ES fill:#fce4ec
    style LS fill:#f3e5f5
    style OTEL fill:#fff3e0
    style K fill:#e0f2f1
    style J fill:#fff8e1
    style P fill:#e8f5e8
    style A fill:#fff3e0
    style NODE fill:#e1f5fe
    style PYTHON fill:#e1f5fe
    style OTHER fill:#e1f5fe
```

## Configuração de Segurança e Monitoramento

```mermaid
graph TB
    subgraph "Camada de Segurança"
        NGINX[Nginx<br/>SSL/TLS + Auth]
        TRAEFIK[Traefik<br/>Load Balancer]
    end

    subgraph "Monitoramento"
        PROMETHEUS[Prometheus<br/>Métricas]
        ALERTMANAGER[Alertmanager<br/>Alertas]
    end

    subgraph "Alertas Configurados"
        ES_DOWN[Elasticsearch Down]
        KIBANA_DOWN[Kibana Down]
        PROMETHEUS_DOWN[Prometheus Down]
        OTEL_DOWN[OpenTelemetry Down]
    end

    subgraph "Filtros de Segurança"
        SENSITIVE[Remoção de Dados Sensíveis<br/>password, token, secret]
        AUTH[Autenticação Básica<br/>Kibana]
        RATE_LIMIT[Rate Limiting<br/>5 req/min]
    end

    NGINX -->|SSL + Auth| TRAEFIK
    TRAEFIK -->|Proxy Seguro| PROMETHEUS
    TRAEFIK -->|Proxy Seguro| ALERTMANAGER

    PROMETHEUS -->|Health Checks| ES_DOWN
    PROMETHEUS -->|Health Checks| KIBANA_DOWN
    PROMETHEUS -->|Health Checks| PROMETHEUS_DOWN
    PROMETHEUS -->|Health Checks| OTEL_DOWN

    ES_DOWN --> ALERTMANAGER
    KIBANA_DOWN --> ALERTMANAGER
    PROMETHEUS_DOWN --> ALERTMANAGER
    OTEL_DOWN --> ALERTMANAGER

    SENSITIVE -.->|Processamento| PROMETHEUS
    AUTH -.->|Acesso| NGINX
    RATE_LIMIT -.->|Proteção| NGINX

    style NGINX fill:#ffebee
    style TRAEFIK fill:#ffebee
    style PROMETHEUS fill:#e8f5e8
    style ALERTMANAGER fill:#fff3e0
    style SENSITIVE fill:#fce4ec
    style AUTH fill:#fce4ec
    style RATE_LIMIT fill:#fce4ec
```

## Escalabilidade e Performance

```mermaid
graph TB
    subgraph "Limites de Capacidade"
        APPS[Até 100 Aplicações<br/>Simultâneas]
        LOGS[50.000 Logs/minuto<br/>Processamento]
        TRACES[10.000 Traces/minuto<br/>Rastreamento]
        METRICS[1.000 Métricas/segundo<br/>Coleta]
    end

    subgraph "Recursos de Sistema"
        CPU[CPU: < 80% por Container]
        MEM[Memória: < 85% por Container]
        DISK[Disco: < 90% Total]
        NET[Rede: < 1Gbps por Serviço]
    end

    subgraph "Retenção de Dados"
        LOGS_RET[Logs: 30-90 dias<br/>Configurável]
        TRACES_RET[Traces: 7-30 dias<br/>Configurável]
        METRICS_RET[Métricas: 90-365 dias<br/>Configurável]
    end

    subgraph "Backup e Recuperação"
        BACKUP[Backup Automático<br/>Diário]
        RESTORE[Recuperação<br/>< 1 hora]
    end

    subgraph "Performance"
        LATENCY[Latência: < 100ms<br/>Consultas]
        UPTIME[Disponibilidade: 99.9%<br/>Uptime]
    end

    APPS --> CPU
    LOGS --> MEM
    TRACES --> DISK
    METRICS --> NET

    LOGS_RET --> BACKUP
    TRACES_RET --> BACKUP
    METRICS_RET --> BACKUP

    BACKUP --> RESTORE
    RESTORE --> UPTIME

    CPU --> LATENCY
    MEM --> LATENCY
    DISK --> LATENCY
    NET --> LATENCY

    style APPS fill:#e1f5fe
    style LOGS fill:#f3e5f5
    style TRACES fill:#fff8e1
    style METRICS fill:#e8f5e8
    style CPU fill:#ffebee
    style MEM fill:#ffebee
    style DISK fill:#ffebee
    style NET fill:#ffebee
    style BACKUP fill:#e0f2f1
    style UPTIME fill:#e0f2f1
```

## Tecnologias e Versões

```mermaid
graph LR
    subgraph "Stack Principal"
        ES[Elasticsearch 8.9.1]
        K[Kibana 8.9.1]
        LS[Logstash 8.9.1]
    end

    subgraph "Observabilidade"
        OTEL[OpenTelemetry Collector 0.96.0]
        J[Jaeger 1.55.0]
        P[Prometheus 2.48.1]
        AM[Alertmanager 0.26.0]
    end

    subgraph "Infraestrutura"
        DOCKER[Docker Compose]
        TRAEFIK[Traefik Load Balancer]
        NGINX[Nginx Reverse Proxy]
    end

    subgraph "Aplicações"
        NODE[Node.js 16+]
        PYTHON[Python 3.8+]
        WINSTON[Winston Logger]
    end

    ES --> K
    LS --> ES
    OTEL --> J
    OTEL --> P
    OTEL --> LS
    P --> AM

    DOCKER --> ES
    DOCKER --> K
    DOCKER --> LS
    DOCKER --> OTEL
    DOCKER --> J
    DOCKER --> P
    DOCKER --> AM

    TRAEFIK --> K
    TRAEFIK --> J
    TRAEFIK --> P
    TRAEFIK --> AM

    NODE --> OTEL
    NODE --> LS
    PYTHON --> OTEL
    PYTHON --> LS
    WINSTON --> LS

    style ES fill:#fce4ec
    style K fill:#e0f2f1
    style LS fill:#f3e5f5
    style OTEL fill:#fff3e0
    style J fill:#fff8e1
    style P fill:#e8f5e8
    style AM fill:#fff3e0
    style DOCKER fill:#e3f2fd
    style TRAEFIK fill:#ffebee
    style NGINX fill:#ffebee
    style NODE fill:#e1f5fe
    style PYTHON fill:#e1f5fe
    style WINSTON fill:#f3e5f5
```

---

**Sistema Gwan APM - Observabilidade Completa** 🚀

Este sistema oferece uma solução completa de observabilidade com logs estruturados, traces distribuídos e métricas de performance, tudo integrado e correlacionado para facilitar o debugging e monitoramento de aplicações em produção.
