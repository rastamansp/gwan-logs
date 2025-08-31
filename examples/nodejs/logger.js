// Exemplo de configuração de logger para Node.js
// Integração com Elasticsearch para Gwan Logs

const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

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

// Middleware para Express
const loggerMiddleware = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.id || 'anonymous'
    });
  });
  
  next();
};

// Funções de log personalizadas
const logError = (error, context = {}) => {
  logger.error('Application Error', {
    error: {
      message: error.message,
      stack: error.stack,
      code: error.code
    },
    context
  });
};

const logPerformance = (operation, duration, metadata = {}) => {
  logger.info('Performance Metric', {
    operation,
    duration: `${duration}ms`,
    ...metadata
  });
};

const logSecurity = (event, details = {}) => {
  logger.warn('Security Event', {
    event,
    details,
    timestamp: new Date().toISOString()
  });
};

module.exports = {
  logger,
  loggerMiddleware,
  logError,
  logPerformance,
  logSecurity
};
