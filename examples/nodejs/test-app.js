const net = require('net');
const fs = require('fs');

// Configurações do Logstash
const LOGSTASH_HOST = 'localhost';
const LOGSTASH_PORT = 5044;

// Função para gerar logs de exemplo
function generateLog(level, message, data = {}) {
  return {
    timestamp: new Date().toISOString(),
    level: level,
    message: message,
    service: 'test-nodejs-app',
    environment: 'development',
    data: data,
    host: require('os').hostname()
  };
}

// Função para enviar log para Logstash
function sendToLogstash(logData) {
  return new Promise((resolve, reject) => {
    const client = new net.Socket();
    
    client.connect(LOGSTASH_PORT, LOGSTASH_HOST, () => {
      console.log(`Conectado ao Logstash em ${LOGSTASH_HOST}:${LOGSTASH_PORT}`);
      
      // Envia o log como JSON
      const logJson = JSON.stringify(logData) + '\n';
      client.write(logJson);
      
      client.end();
      resolve();
    });
    
    client.on('error', (err) => {
      console.error('Erro ao conectar com Logstash:', err.message);
      reject(err);
    });
    
    client.on('close', () => {
      console.log('Conexão com Logstash fechada');
    });
  });
}

// Função para simular atividade da aplicação
async function simulateAppActivity() {
  console.log('🚀 Iniciando aplicação de teste Node.js...');
  
  // Log de inicialização
  await sendToLogstash(generateLog('info', 'Aplicação iniciada com sucesso', {
    version: '1.0.0',
    port: 3000
  }));
  
  // Simular algumas operações
  const operations = [
    { level: 'info', message: 'Usuário fez login', data: { userId: 123, ip: '192.168.1.100' } },
    { level: 'warn', message: 'Tentativa de acesso a recurso restrito', data: { userId: 123, resource: '/admin' } },
    { level: 'error', message: 'Erro ao conectar com banco de dados', data: { error: 'Connection timeout', retryCount: 3 } },
    { level: 'info', message: 'Requisição processada com sucesso', data: { method: 'GET', path: '/api/users', duration: 45 } },
    { level: 'debug', message: 'Cache miss para chave', data: { key: 'user:123:profile', cacheHit: false } }
  ];
  
  for (let i = 0; i < operations.length; i++) {
    const op = operations[i];
    await sendToLogstash(generateLog(op.level, op.message, op.data));
    
    // Aguarda um pouco entre as operações
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  // Log de finalização
  await sendToLogstash(generateLog('info', 'Aplicação finalizada', {
    uptime: '5s',
    requestsProcessed: operations.length
  }));
  
  console.log('✅ Teste concluído! Verifique os logs no Kibana.');
}

// Executa o teste
simulateAppActivity().catch(console.error);
