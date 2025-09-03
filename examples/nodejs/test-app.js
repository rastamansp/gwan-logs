const express = require('express');
const { logger, loggerMiddleware, logError, logPerformance } = require('./logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(loggerMiddleware);

// Rotas de teste
app.get('/', (req, res) => {
  logger.info('Acesso à rota raiz');
  res.json({
    message: 'Gwan APM - Sistema de Observabilidade',
    timestamp: new Date().toISOString(),
    service: 'gwan-app',
    version: '1.0.0'
  });
});

app.get('/health', (req, res) => {
  logger.info('Health check realizado');
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.get('/error', (req, res) => {
  try {
    throw new Error('Erro de teste para verificar logs');
  } catch (error) {
    logError(error, { route: '/error' });
    res.status(500).json({
      error: 'Erro interno do servidor',
      message: error.message
    });
  }
});

app.get('/performance', (req, res) => {
  const start = Date.now();
  
  // Simula uma operação demorada
  setTimeout(() => {
    const duration = Date.now() - start;
    logPerformance('slow-operation', duration, { 
      operation: 'simulated-work',
      complexity: 'high'
    });
    
    res.json({
      message: 'Operação de performance concluída',
      duration: `${duration}ms`,
      timestamp: new Date().toISOString()
    });
  }, Math.random() * 2000 + 500); // 500ms a 2.5s
});

// Middleware de erro
app.use((err, req, res, next) => {
  logError(err, { 
    route: req.path,
    method: req.method 
  });
  
  res.status(500).json({
    error: 'Erro interno do servidor',
    message: err.message
  });
});

// Inicia o servidor
app.listen(PORT, () => {
  logger.info(`Servidor iniciado na porta ${PORT}`, {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    nodeVersion: process.version
  });
  
  console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔍 Teste de erro: http://localhost:${PORT}/error`);
  console.log(`⚡ Teste de performance: http://localhost:${PORT}/performance`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  logger.info('Recebido SIGINT, desligando servidor...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('Recebido SIGTERM, desligando servidor...');
  process.exit(0);
});
