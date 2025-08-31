# Exemplo Node.js - Teste de Logs

Este exemplo demonstra como enviar logs de uma aplicação Node.js para o stack ELK (Elasticsearch + Logstash + Kibana).

## Pré-requisitos

1. Stack ELK rodando (Elasticsearch, Logstash, Kibana)
2. Node.js 14+ instalado
3. Porta 5044 do Logstash acessível

## Como usar

### 1. Verificar se o stack ELK está rodando

```bash
docker-compose ps
```

Certifique-se de que todos os serviços estão com status "Up".

### 2. Executar a aplicação de teste

```bash
cd examples/nodejs
npm start
```

### 3. Verificar os logs no Kibana

1. Acesse o Kibana: `http://localhost:5601` ou `http://kibana.gwan.com.br`
2. Vá em **Discover**
3. Selecione o índice `gwan-logs-*`
4. Configure o filtro de tempo para "Last 15 minutes"
5. Procure por logs com `service: "test-nodejs-app"`

## Estrutura dos Logs

A aplicação gera logs com a seguinte estrutura:

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "info",
  "message": "Aplicação iniciada com sucesso",
  "service": "test-nodejs-app",
  "environment": "development",
  "data": {
    "version": "1.0.0",
    "port": 3000
  },
  "host": "seu-hostname"
}
```

## Tipos de Logs Gerados

- **info**: Inicialização, login de usuário, requisições processadas
- **warn**: Tentativas de acesso a recursos restritos
- **error**: Erros de conexão com banco de dados
- **debug**: Informações de cache

## Personalização

Para personalizar os logs, edite o arquivo `test-app.js`:

1. Modifique a função `generateLog()` para adicionar campos customizados
2. Altere as operações na função `simulateAppActivity()`
3. Ajuste o intervalo entre logs (atualmente 1 segundo)

## Troubleshooting

### Erro de conexão com Logstash

Se receber erro de conexão, verifique:

1. Se o Logstash está rodando: `docker logs gwan-logstash`
2. Se a porta 5044 está acessível: `telnet localhost 5044`
3. Se o pipeline do Logstash está configurado corretamente

### Logs não aparecem no Kibana

1. Verifique se o Elasticsearch está saudável: `curl http://localhost:9200/_cluster/health`
2. Confirme se o índice foi criado: `curl http://localhost:9200/_cat/indices`
3. Verifique os logs do Logstash: `docker logs gwan-logstash`

## Próximos Passos

- Integrar com Winston ou Bunyan para logging estruturado
- Adicionar métricas e alertas
- Configurar diferentes ambientes (dev, staging, prod)
- Implementar rotação de logs
