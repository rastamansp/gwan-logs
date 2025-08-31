#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Exemplo de configuração de logger para Python
Integração com Elasticsearch para Gwan Logs
"""

import logging
import json
import os
import socket
from datetime import datetime
from elasticsearch import Elasticsearch
from pythonjsonlogger import jsonlogger

class GwanLogger:
    """
    Logger personalizado para aplicações Gwan com formato estruturado
    """
    
    def __init__(self, service_name='gwan-app', environment='production'):
        self.service_name = service_name
        self.environment = environment
        self.hostname = socket.gethostname()
        self.pid = os.getpid()
        
        # Configurar Elasticsearch
        self.es_client = Elasticsearch(
            [os.getenv('ELASTICSEARCH_URL', 'http://elasticsearch:9200')],
            basic_auth=(
                os.getenv('ELASTIC_USERNAME', 'elastic'),
                os.getenv('ELASTIC_PASSWORD', 'GwanLogs2024!')
            ),
            verify_certs=False
        )
        
        # Configurar logger
        self.logger = logging.getLogger(service_name)
        self.logger.setLevel(logging.INFO)
        
        # Formato personalizado
        self.formatter = jsonlogger.JsonFormatter(
            fmt='%(timestamp)s %(level)s %(message)s %(service)s %(environment)s %(hostname)s %(pid)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # Handler para console
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(self.formatter)
        self.logger.addHandler(console_handler)
        
        # Handler para Elasticsearch
        self.es_handler = ElasticsearchHandler(
            self.es_client,
            index_prefix='gwan-logs',
            service_name=service_name,
            environment=environment
        )
        self.logger.addHandler(self.es_handler)
    
    def _format_log(self, level, message, **kwargs):
        """Formata log com metadados estruturados"""
        log_data = {
            '@timestamp': datetime.utcnow().isoformat(),
            'level': level.upper(),
            'message': message,
            'service': self.service_name,
            'environment': self.environment,
            'hostname': self.hostname,
            'pid': self.pid,
            'version': os.getenv('APP_VERSION', '1.0.0'),
            **kwargs
        }
        return log_data
    
    def info(self, message, **kwargs):
        """Log de informação"""
        log_data = self._format_log('info', message, **kwargs)
        self.logger.info(json.dumps(log_data))
    
    def error(self, message, error=None, **kwargs):
        """Log de erro"""
        log_data = self._format_log('error', message, **kwargs)
        if error:
            log_data['error'] = {
                'message': str(error),
                'type': type(error).__name__,
                'traceback': getattr(error, '__traceback__', None)
            }
        self.logger.error(json.dumps(log_data))
    
    def warn(self, message, **kwargs):
        """Log de aviso"""
        log_data = self._format_log('warn', message, **kwargs)
        self.logger.warning(json.dumps(log_data))
    
    def debug(self, message, **kwargs):
        """Log de debug"""
        log_data = self._format_log('debug', message, **kwargs)
        self.logger.debug(json.dumps(log_data))
    
    def performance(self, operation, duration_ms, **kwargs):
        """Log de performance"""
        log_data = self._format_log('info', f'Performance: {operation}', 
                                  operation=operation, 
                                  duration_ms=duration_ms,
                                  log_type='performance',
                                  **kwargs)
        self.logger.info(json.dumps(log_data))
    
    def security(self, event, details=None, **kwargs):
        """Log de segurança"""
        log_data = self._format_log('warn', f'Security: {event}',
                                  event=event,
                                  details=details or {},
                                  log_type='security',
                                  **kwargs)
        self.logger.warning(json.dumps(log_data))
    
    def audit(self, action, resource, user_id, **kwargs):
        """Log de auditoria"""
        log_data = self._format_log('info', f'Audit: {action} on {resource}',
                                  action=action,
                                  resource=resource,
                                  user_id=user_id,
                                  log_type='audit',
                                  **kwargs)
        self.logger.info(json.dumps(log_data))


class ElasticsearchHandler(logging.Handler):
    """Handler personalizado para Elasticsearch"""
    
    def __init__(self, es_client, index_prefix='gwan-logs', service_name='gwan-app', environment='production'):
        super().__init__()
        self.es_client = es_client
        self.index_prefix = index_prefix
        self.service_name = service_name
        self.environment = environment
        
        # Criar template de índice
        self._create_index_template()
    
    def _create_index_template(self):
        """Cria template de índice no Elasticsearch"""
        template_name = f"{self.index_prefix}-template"
        template_body = {
            "index_patterns": [f"{self.index_prefix}-*"],
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 0,
                "index.lifecycle.name": "logs",
                "index.lifecycle.rollover_alias": self.index_prefix
            },
            "mappings": {
                "properties": {
                    "@timestamp": {"type": "date"},
                    "level": {"type": "keyword"},
                    "message": {"type": "text"},
                    "service": {"type": "keyword"},
                    "environment": {"type": "keyword"},
                    "hostname": {"type": "keyword"},
                    "pid": {"type": "integer"},
                    "version": {"type": "keyword"},
                    "log_type": {"type": "keyword"},
                    "error": {
                        "properties": {
                            "message": {"type": "text"},
                            "type": {"type": "keyword"},
                            "traceback": {"type": "text"}
                        }
                    }
                }
            }
        }
        
        try:
            self.es_client.indices.put_template(name=template_name, body=template_body)
        except Exception as e:
            print(f"Erro ao criar template: {e}")
    
    def emit(self, record):
        """Envia log para Elasticsearch"""
        try:
            # Formatar log
            log_data = json.loads(record.getMessage())
            
            # Criar nome do índice com data
            index_name = f"{self.index_prefix}-{datetime.now().strftime('%Y.%m.%d')}"
            
            # Enviar para Elasticsearch
            self.es_client.index(
                index=index_name,
                body=log_data,
                id=None  # Deixar Elasticsearch gerar ID
            )
        except Exception as e:
            print(f"Erro ao enviar log para Elasticsearch: {e}")


# Exemplo de uso
if __name__ == "__main__":
    # Criar logger
    logger = GwanLogger(service_name='test-app', environment='development')
    
    # Exemplos de logs
    logger.info("Aplicação iniciada", port=3000, host="localhost")
    
    try:
        # Simular erro
        raise ValueError("Erro de teste")
    except Exception as e:
        logger.error("Erro na aplicação", error=e, context="main")
    
    logger.warn("Aviso importante", user_count=150)
    
    logger.performance("database_query", 150, table="users", query="SELECT *")
    
    logger.security("failed_login", {
        "ip": "192.168.1.1",
        "username": "testuser",
        "attempts": 3
    })
    
    logger.audit("create", "user", "admin", target_user="12345")
