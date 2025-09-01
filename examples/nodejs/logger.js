// Exemplo de configuração de logger para Node.js
// Integração com Elasticsearch para Gwan Logs + OpenTelemetry

const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { trace, metrics } = require('@opentelemetry/api');

// Configuração do OpenTelemetry
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'gwan-app',
    [SemanticResourceAttributes.SERVICE_VERSION]: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'production',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/metrics',
    }),
    exportIntervalMillis: 1000,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

// Inicializa o SDK
sdk.start();

// Métricas OpenTelemetry
const meter = metrics.getMeter('gwan-app');
const requestCounter = meter.createCounter('requests_total', {
  description: 'Total de requisições',
});
const requestDuration = meter.createHistogram('request_duration', {
  description: 'Duração das requisições',
  unit: 'ms',
});
const errorCounter = meter.createCounter('errors_total', {
  description: 'Total de erros',
});

// Formato personalizado para logs
const customFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf(({ timestamp, level, message, service, ...meta }) => {
    return JSON.stringify({
      '@timestamp': timestamp,
      level: level.toUpperCase(),
      message,
      service: service || 'gwan-app',
      environment: process.env.NODE_ENV || 'production',
      hostname: require('os').hostname(),
      pid: process.pid,
      ...meta
    });
  })
);

// Configuração do logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: customFormat,
  defaultMeta: {
    service: 'gwan-app',
    version: process.env.APP_VERSION || '1.0.0'
  },
  transports: [
    // Console para desenvolvimento
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    
    // Elasticsearch para produção
    new ElasticsearchTransport({
      level: 'info',
      clientOpts: {
        node: process.env.ELASTICSEARCH_URL || 'http://elasticsearch:9200',
        auth: {
          username: process.env.ELASTIC_USERNAME || 'elastic',
          password: process.env.ELASTIC_PASSWORD || 'GwanLogs2024!'
        },
        tls: {
          rejectUnauthorized: false
        }
      },
      indexPrefix: 'gwan-logs',
      ensureMappingTemplate: true,
      mappingTemplate: {
        index_patterns: ['gwan-logs-*'],
        settings: {
          number_of_shards: 1,
          number_of_replicas: 0,
          'index.lifecycle.name': 'logs',
          'index.lifecycle.rollover_alias': 'gwan-logs'
        },
        mappings: {
          properties: {
            '@timestamp': { type: 'date' },
            level: { type: 'keyword' },
            message: { type: 'text' },
            service: { type: 'keyword' },
            environment: { type: 'keyword' },
            hostname: { type: 'keyword' },
            pid: { type: 'integer' },
            version: { type: 'keyword' },
            error: {
              properties: {
                message: { type: 'text' },
                stack: { type: 'text' },
                code: { type: 'keyword' }
              }
            }
          }
        }
      }
    })
  ]
});

// Middleware para Express com OpenTelemetry
const loggerMiddleware = (req, res, next) => {
  const start = Date.now();
  const tracer = trace.getTracer('gwan-app');
  
  // Cria span para a requisição
  const span = tracer.startSpan('http-request', {
    attributes: {
      'http.method': req.method,
      'http.url': req.url,
      'http.user_agent': req.get('User-Agent'),
      'http.remote_ip': req.ip,
    }
  });
  
  // Adiciona span ao contexto
  const ctx = trace.setSpan(trace.active(), span);
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    // Atualiza span com informações da resposta
    span.setAttributes({
      'http.status_code': res.statusCode,
      'http.response_size': res.get('Content-Length'),
    });
    
    // Incrementa métricas
    requestCounter.add(1, {
      method: req.method,
      path: req.path,
      status: res.statusCode,
    });
    
    requestDuration.record(duration, {
      method: req.method,
      path: req.path,
      status: res.statusCode,
    });
    
    // Log estruturado
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.id || 'anonymous',
      traceId: span.spanContext().traceId,
      spanId: span.spanContext().spanId,
    });
    
    // Finaliza span
    span.end();
  });
  
  next();
};

// Funções de log personalizadas com OpenTelemetry
const logError = (error, context = {}) => {
  const tracer = trace.getTracer('gwan-app');
  const span = tracer.startSpan('error-handler');
  
  // Incrementa contador de erros
  errorCounter.add(1, {
    error_type: error.constructor.name,
    service: 'gwan-app',
  });
  
  // Registra erro no span
  span.recordException(error);
  span.setStatus({ code: 2, message: error.message });
  
  logger.error('Application Error', {
    error: {
      message: error.message,
      stack: error.stack,
      code: error.code
    },
    context,
    traceId: span.spanContext().traceId,
    spanId: span.spanContext().spanId,
  });
  
  span.end();
};

const logPerformance = (operation, duration, metadata = {}) => {
  const tracer = trace.getTracer('gwan-app');
  const span = tracer.startSpan('performance-metric');
  
  span.setAttributes({
    'operation.name': operation,
    'operation.duration': duration,
    ...metadata
  });
  
  logger.info('Performance Metric', {
    operation,
    duration: `${duration}ms`,
    ...metadata,
    traceId: span.spanContext().traceId,
    spanId: span.spanContext().spanId,
  });
  
  span.end();
};

const logSecurity = (event, details = {}) => {
  const tracer = trace.getTracer('gwan-app');
  const span = tracer.startSpan('security-event');
  
  span.setAttributes({
    'security.event': event,
    ...details
  });
  
  logger.warn('Security Event', {
    event,
    details,
    timestamp: new Date().toISOString(),
    traceId: span.spanContext().traceId,
    spanId: span.spanContext().spanId,
  });
  
  span.end();
};

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => {
      logger.info('OpenTelemetry SDK desligado com sucesso');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('Erro ao desligar OpenTelemetry SDK:', error);
      process.exit(1);
    });
});

module.exports = {
  logger,
  loggerMiddleware,
  logError,
  logPerformance,
  logSecurity,
  sdk
};
