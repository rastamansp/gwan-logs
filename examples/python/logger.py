#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Exemplo de configuração de logger para Python
Integração com Elasticsearch para Gwan Logs
"""

import logging
import json
import os
import sys
from datetime import datetime
from typing import Dict, Any, Optional
from pythonjsonlogger import jsonlogger
from elasticsearch import Elasticsearch
import socket
import uuid

class GwanLogger:
    """Logger personalizado para integração com Gwan Logs"""
    
    def __init__(self, 
                 service_name: str = None,
                 environment: str = None,
                 version: str = None,
                 elasticsearch_url: str = None,
                 elasticsearch_username: str = None,
                 elasticsearch_password: str = None):
        
        self.service_name = service_name or os.getenv('SERVICE_NAME', 'python-app')
        self.environment = environment or os.getenv('NODE_ENV', 'development')
        self.version = version or os.getenv('APP_VERSION', '1.0.0')
        self.hostname = socket.gethostname()
        
        # Configurações do Elasticsearch
        self.elasticsearch_url = elasticsearch_url or os.getenv('ELASTICSEARCH_URL', 'http://elasticsearch:9200')
        self.elasticsearch_username = elasticsearch_username or os.getenv('ELASTICSEARCH_USERNAME', 'elastic')
        self.elasticsearch_password = elasticsearch_password or os.getenv('ELASTICSEARCH_PASSWORD', 'GwanLogs2024!')
        
        # Configurar logger
        self.logger = self._setup_logger()
        
        # Cliente Elasticsearch para logs diretos
        self.es_client = self._setup_elasticsearch_client()
    
    def _setup_logger(self) -> logging.Logger:
        """Configurar o logger principal"""
        logger = logging.getLogger(self.service_name)
        logger.setLevel(logging.INFO)
        
        # Limpar handlers existentes
        logger.handlers.clear()
        
        # Handler para console
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        
        # Formatter JSON para console
        json_formatter = jsonlogger.JsonFormatter(
            fmt='%(timestamp)s %(level)s %(name)s %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        console_handler.setFormatter(json_formatter)
        logger.addHandler(console_handler)
        
        # Handler para arquivo (opcional)
        if os.getenv('LOG_TO_FILE', 'false').lower() == 'true':
            file_handler = logging.FileHandler(f'/var/log/{self.service_name}.log')
            file_handler.setLevel(logging.INFO)
            file_handler.setFormatter(json_formatter)
            logger.addHandler(file_handler)
        
        return logger
    
    def _setup_elasticsearch_client(self) -> Optional[Elasticsearch]:
        """Configurar cliente Elasticsearch"""
        if self.environment == 'production':
            try:
                es_client = Elasticsearch(
                    [self.elasticsearch_url],
                    basic_auth=(self.elasticsearch_username, self.elasticsearch_password),
                    verify_certs=False,
                    ssl_show_warn=False
                )
                
                # Testar conexão
                if es_client.ping():
                    return es_client
                else:
                    self.logger.warning("Elasticsearch não está respondendo")
                    return None
                    
            except Exception as e:
                self.logger.warning(f"Erro ao conectar com Elasticsearch: {e}")
                return None
        
        return None
    
    def _format_log(self, level: str, message: str, **kwargs) -> Dict[str, Any]:
        """Formatar log para Elasticsearch"""
        log_data = {
            '@timestamp': datetime.utcnow().isoformat() + 'Z',
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'level': level.upper(),
            'message': message,
            'service': self.service_name,
            'environment': self.environment,
            'version': self.version,
            'hostname': self.hostname,
            'meta': kwargs
        }
        
        # Adicionar campos extras
        for key, value in kwargs.items():
            if key not in ['@timestamp', 'timestamp', 'level', 'message', 'service', 'environment', 'version', 'hostname']:
                log_data[key] = value
        
        return log_data
    
    def _send_to_elasticsearch(self, log_data: Dict[str, Any]) -> bool:
        """Enviar log para Elasticsearch"""
        if not self.es_client:
            return False
        
        try:
            index_name = f"gwan-logs-python-{datetime.utcnow().strftime('%Y.%m.%d')}"
            
            self.es_client.index(
                index=index_name,
                body=log_data,
                id=str(uuid.uuid4())
            )
            return True
            
        except Exception as e:
            self.logger.warning(f"Erro ao enviar log para Elasticsearch: {e}")
            return False
    
    def info(self, message: str, **kwargs):
        """Log de informação"""
        log_data = self._format_log('info', message, **kwargs)
        self.logger.info(message, extra=log_data)
        self._send_to_elasticsearch(log_data)
    
    def warning(self, message: str, **kwargs):
        """Log de aviso"""
        log_data = self._format_log('warning', message, **kwargs)
        self.logger.warning(message, extra=log_data)
        self._send_to_elasticsearch(log_data)
    
    def error(self, message: str, **kwargs):
        """Log de erro"""
        log_data = self._format_log('error', message, **kwargs)
        self.logger.error(message, extra=log_data)
        self._send_to_elasticsearch(log_data)
    
    def debug(self, message: str, **kwargs):
        """Log de debug"""
        log_data = self._format_log('debug', message, **kwargs)
        self.logger.debug(message, extra=log_data)
        # Debug logs não são enviados para Elasticsearch em produção
    
    def critical(self, message: str, **kwargs):
        """Log crítico"""
        log_data = self._format_log('critical', message, **kwargs)
        self.logger.critical(message, extra=log_data)
        self._send_to_elasticsearch(log_data)
    
    def performance(self, operation: str, duration: float, **kwargs):
        """Log de performance"""
        self.info(
            f"Performance metric: {operation}",
            operation=operation,
            duration_ms=duration,
            **kwargs
        )
    
    def business_event(self, event: str, data: Dict[str, Any], **kwargs):
        """Log de evento de negócio"""
        self.info(
            f"Business event: {event}",
            event=event,
            data=data,
            **kwargs
        )
    
    def security_event(self, event: str, details: Dict[str, Any], **kwargs):
        """Log de evento de segurança"""
        self.warning(
            f"Security event: {event}",
            event=event,
            details=details,
            **kwargs
        )
    
    def audit_log(self, action: str, resource: str, user_id: str, **kwargs):
        """Log de auditoria"""
        self.info(
            f"Audit log: {action} on {resource}",
            action=action,
            resource=resource,
            user_id=user_id,
            **kwargs
        )


class FlaskLoggerMiddleware:
    """Middleware para Flask"""
    
    def __init__(self, app, logger: GwanLogger):
        self.app = app
        self.logger = logger
    
    def __call__(self, environ, start_response):
        # Log da requisição
        request_id = environ.get('HTTP_X_REQUEST_ID', str(uuid.uuid4()))
        
        self.logger.info(
            "Request received",
            method=environ.get('REQUEST_METHOD'),
            url=environ.get('PATH_INFO'),
            ip=environ.get('REMOTE_ADDR'),
            user_agent=environ.get('HTTP_USER_AGENT'),
            request_id=request_id
        )
        
        # Interceptar resposta
        def custom_start_response(status, headers, exc_info=None):
            # Log da resposta
            self.logger.info(
                "Request completed",
                method=environ.get('REQUEST_METHOD'),
                url=environ.get('PATH_INFO'),
                status_code=status.split()[0],
                request_id=request_id
            )
            return start_response(status, headers, exc_info)
        
        return self.app(environ, custom_start_response)


class DjangoLoggerMiddleware:
    """Middleware para Django"""
    
    def __init__(self, logger: GwanLogger):
        self.logger = logger
    
    def __call__(self, request):
        # Log da requisição
        request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
        
        self.logger.info(
            "Request received",
            method=request.method,
            url=request.path,
            ip=request.META.get('REMOTE_ADDR'),
            user_agent=request.META.get('HTTP_USER_AGENT'),
            request_id=request_id
        )
        
        # Processar requisição
        response = self.get_response(request)
        
        # Log da resposta
        self.logger.info(
            "Request completed",
            method=request.method,
            url=request.path,
            status_code=response.status_code,
            request_id=request_id
        )
        
        return response


# Exemplo de uso
if __name__ == "__main__":
    # Criar logger
    logger = GwanLogger(
        service_name="test-python-app",
        environment="development"
    )
    
    # Testes
    logger.info("Logger inicializado com sucesso", test=True)
    
    logger.error(
        "Erro de teste",
        error_code="TEST_ERROR",
        error_message="Este é um erro de teste"
    )
    
    logger.warning(
        "Aviso de teste",
        warning_type="test_warning"
    )
    
    logger.performance(
        "database_query",
        150.5,
        query="SELECT * FROM users",
        table="users"
    )
    
    logger.business_event(
        "user_registration",
        {
            "user_id": "12345",
            "email": "user@example.com"
        },
        source="web_form"
    )
    
    logger.security_event(
        "failed_login",
        {
            "ip": "192.168.1.1",
            "username": "testuser",
            "attempts": 3
        },
        source="auth_service"
    )
    
    logger.audit_log(
        "create",
        "user",
        "admin",
        target_user_id="12345",
        changes=["email", "status"]
    )
    
    print("Testes concluídos!")
