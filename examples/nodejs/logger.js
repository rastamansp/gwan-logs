// Exemplo de configuração de logger para Node.js
// Integração com Elasticsearch para Gwan Logs

const winston = require('winston');
const ElasticsearchTransport = require('winston-elasticsearch').ElasticsearchTransport;

// Configuração do logger
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp({
            format: 'YYYY-MM-DD HH:mm:ss'
        }),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: {
        service: process.env.SERVICE_NAME || 'nodejs-app',
        environment: process.env.NODE_ENV || 'development',
        version: process.env.APP_VERSION || '1.0.0',
        hostname: require('os').hostname()
    },
    transports: [
        // Console transport para desenvolvimento
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        }),
        
        // Elasticsearch transport para produção
        ...(process.env.NODE_ENV === 'production' ? [
            new ElasticsearchTransport({
                level: 'info',
                clientOpts: {
                    node: process.env.ELASTICSEARCH_URL || 'http://elasticsearch:9200',
                    auth: {
                        username: process.env.ELASTICSEARCH_USERNAME || 'elastic',
                        password: process.env.ELASTICSEARCH_PASSWORD || 'GwanLogs2024!'
                    },
                    ssl: {
                        rejectUnauthorized: false
                    }
                },
                index: 'gwan-logs-nodejs',
                ensureMappingTemplate: true,
                mappingTemplate: {
                    index_patterns: ['gwan-logs-nodejs*'],
                    settings: {
                        number_of_shards: 1,
                        number_of_replicas: 0,
                        index: {
                            refresh_interval: '5s'
                        }
                    },
                    mappings: {
                        properties: {
                            '@timestamp': {
                                type: 'date'
                            },
                            message: {
                                type: 'text'
                            },
                            level: {
                                type: 'keyword'
                            },
                            service: {
                                type: 'keyword'
                            },
                            environment: {
                                type: 'keyword'
                            },
                            version: {
                                type: 'keyword'
                            },
                            hostname: {
                                type: 'keyword'
                            },
                            timestamp: {
                                type: 'date'
                            },
                            meta: {
                                type: 'object',
                                dynamic: true
                            }
                        }
                    }
                }
            })
        ] : [])
    ]
});

// Middleware para Express.js
const loggerMiddleware = (req, res, next) => {
    const start = Date.now();
    
    // Log da requisição
    logger.info('Request received', {
        method: req.method,
        url: req.url,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        meta: {
            requestId: req.headers['x-request-id'] || require('crypto').randomUUID(),
            userId: req.user?.id,
            sessionId: req.session?.id
        }
    });

    // Interceptar resposta
    res.on('finish', () => {
        const duration = Date.now() - start;
        
        logger.info('Request completed', {
            method: req.method,
            url: req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            contentLength: res.get('Content-Length'),
            meta: {
                requestId: req.headers['x-request-id'] || require('crypto').randomUUID()
            }
        });
    });

    next();
};

// Função para log de erros
const errorLogger = (error, req, res, next) => {
    logger.error('Application error', {
        error: {
            message: error.message,
            stack: error.stack,
            name: error.name
        },
        request: {
            method: req.method,
            url: req.url,
            ip: req.ip,
            userAgent: req.get('User-Agent')
        },
        meta: {
            requestId: req.headers['x-request-id'] || require('crypto').randomUUID(),
            userId: req.user?.id
        }
    });

    next(error);
};

// Função para log de performance
const performanceLogger = (operation, duration, metadata = {}) => {
    logger.info('Performance metric', {
        operation,
        duration: `${duration}ms`,
        meta: metadata
    });
};

// Função para log de negócio
const businessLogger = (event, data, metadata = {}) => {
    logger.info('Business event', {
        event,
        data,
        meta: metadata
    });
};

// Função para log de segurança
const securityLogger = (event, details, metadata = {}) => {
    logger.warn('Security event', {
        event,
        details,
        meta: metadata
    });
};

// Função para log de auditoria
const auditLogger = (action, resource, userId, metadata = {}) => {
    logger.info('Audit log', {
        action,
        resource,
        userId,
        timestamp: new Date().toISOString(),
        meta: metadata
    });
};

// Exemplo de uso
if (require.main === module) {
    // Teste do logger
    logger.info('Logger inicializado com sucesso', {
        meta: {
            test: true,
            timestamp: new Date().toISOString()
        }
    });

    logger.error('Erro de teste', {
        error: {
            message: 'Este é um erro de teste',
            code: 'TEST_ERROR'
        }
    });

    logger.warn('Aviso de teste', {
        meta: {
            warning: 'Este é um aviso de teste'
        }
    });

    performanceLogger('database_query', 150, {
        query: 'SELECT * FROM users',
        table: 'users'
    });

    businessLogger('user_registration', {
        userId: '12345',
        email: 'user@example.com'
    }, {
        source: 'web_form'
    });

    securityLogger('failed_login', {
        ip: '192.168.1.1',
        username: 'testuser',
        attempts: 3
    }, {
        source: 'auth_service'
    });

    auditLogger('create', 'user', 'admin', {
        targetUserId: '12345',
        changes: ['email', 'status']
    });
}

module.exports = {
    logger,
    loggerMiddleware,
    errorLogger,
    performanceLogger,
    businessLogger,
    securityLogger,
    auditLogger
};
