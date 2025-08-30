#!/bin/bash

# Script de Instalação do Gwan Logs
# Este script configura o ambiente e instala o stack de logs

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   error "Este script deve ser executado como root"
fi

log "Iniciando instalação do Gwan Logs..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado. Instale o Docker primeiro."
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
fi

# Criar diretórios necessários
log "Criando diretórios de dados..."
mkdir -p /opt/gwan-logs/{elasticsearch,kibana,filebeat,logstash,prometheus,backups}
mkdir -p /opt/gwan-logs/ssl

# Definir permissões
chmod 755 /opt/gwan-logs
chmod 755 /opt/gwan-logs/*

# Verificar se o arquivo .env existe
if [ ! -f .env ]; then
    warn "Arquivo .env não encontrado. Copiando do exemplo..."
    cp env.example .env
    warn "Por favor, edite o arquivo .env com suas configurações antes de continuar."
    read -p "Pressione Enter após editar o arquivo .env..."
fi

# Verificar se os certificados SSL existem
if [ ! -f configs/nginx/ssl/gwan.com.br.crt ] || [ ! -f configs/nginx/ssl/gwan.com.br.key ]; then
    warn "Certificados SSL não encontrados. Criando certificados auto-assinados..."
    mkdir -p configs/nginx/ssl
    
    # Gerar certificado auto-assinado
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout configs/nginx/ssl/gwan.com.br.key \
        -out configs/nginx/ssl/gwan.com.br.crt \
        -subj "/C=BR/ST=SP/L=Sao Paulo/O=Gwan/OU=IT/CN=*.gwan.com.br"
    
    chmod 600 configs/nginx/ssl/gwan.com.br.key
    chmod 644 configs/nginx/ssl/gwan.com.br.crt
fi

# Criar arquivo de senhas para autenticação básica
if [ ! -f configs/nginx/.htpasswd ]; then
    log "Criando arquivo de autenticação básica..."
    echo "admin:\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi" > configs/nginx/.htpasswd
    # Senha: password
    warn "Usuário padrão: admin, Senha: password"
fi

# Verificar se os volumes Docker existem
log "Verificando volumes Docker..."
if ! docker volume ls | grep -q "gwan-logs"; then
    log "Criando volumes Docker..."
    docker volume create gwan-logs-elasticsearch
    docker volume create gwan-logs-kibana
    docker volume create gwan-logs-filebeat
    docker volume create gwan-logs-logstash
    docker volume create gwan-logs-prometheus
fi

# Carregar variáveis de ambiente
log "Carregando variáveis de ambiente..."
source .env

# Verificar se as portas estão livres
log "Verificando portas..."
PORTS=(9200 5601 5044 9090 80 443)
for port in "${PORTS[@]}"; do
    if netstat -tuln | grep -q ":$port "; then
        warn "Porta $port já está em uso. Verifique se não há conflitos."
    fi
done

# Verificar espaço em disco
log "Verificando espaço em disco..."
DISK_SPACE=$(df /opt/gwan-logs | awk 'NR==2 {print $4}')
if [ "$DISK_SPACE" -lt 10485760 ]; then # 10GB em KB
    error "Espaço insuficiente em disco. Necessário pelo menos 10GB livre."
fi

# Verificar memória disponível
log "Verificando memória disponível..."
MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if [ "$MEMORY" -lt 4096 ]; then # 4GB
    warn "Memória RAM baixa detectada. Recomendado pelo menos 4GB para melhor performance."
fi

# Iniciar os serviços
log "Iniciando serviços..."
docker-compose up -d

# Aguardar os serviços iniciarem
log "Aguardando serviços iniciarem..."
sleep 30

# Verificar status dos serviços
log "Verificando status dos serviços..."
for service in elasticsearch kibana filebeat logstash nginx monitoring; do
    if docker-compose ps | grep -q "$service.*Up"; then
        log "✓ $service está rodando"
    else
        error "✗ $service não está rodando"
    fi
done

# Configurar índices e templates
log "Configurando índices e templates..."
sleep 10

# Verificar se o Elasticsearch está respondendo
if curl -u "elastic:$ELASTIC_PASSWORD" -k "http://localhost:9200/_cluster/health" &> /dev/null; then
    log "✓ Elasticsearch está respondendo"
else
    error "✗ Elasticsearch não está respondendo"
fi

# Configurar políticas de ILM
log "Configurando políticas de retenção..."
curl -u "elastic:$ELASTIC_PASSWORD" -X PUT "http://localhost:9200/_ilm/policy/gwan-logs-policy" \
    -H "Content-Type: application/json" \
    -d '{
        "policy": {
            "phases": {
                "hot": {
                    "min_age": "0ms",
                    "actions": {
                        "rollover": {
                            "max_age": "1d",
                            "max_size": "10gb"
                        }
                    }
                },
                "warm": {
                    "min_age": "1d",
                    "actions": {
                        "forcemerge": {
                            "max_num_segments": 1
                        }
                    }
                },
                "cold": {
                    "min_age": "7d",
                    "actions": {}
                },
                "delete": {
                    "min_age": "30d",
                    "actions": {
                        "delete": {}
                    }
                }
            }
        }
    }' || warn "Erro ao configurar política de ILM"

# Configurar templates de índice
log "Configurando templates de índice..."
curl -u "elastic:$ELASTIC_PASSWORD" -X PUT "http://localhost:9200/_template/gwan-logs-template" \
    -H "Content-Type: application/json" \
    -d '{
        "index_patterns": ["gwan-logs-*"],
        "settings": {
            "number_of_shards": 1,
            "number_of_replicas": 0,
            "index.lifecycle.name": "gwan-logs-policy",
            "index.lifecycle.rollover_alias": "gwan-logs"
        },
        "mappings": {
            "properties": {
                "@timestamp": {
                    "type": "date"
                },
                "message": {
                    "type": "text"
                },
                "level": {
                    "type": "keyword"
                },
                "container_name": {
                    "type": "keyword"
                },
                "image_name": {
                    "type": "keyword"
                }
            }
        }
    }' || warn "Erro ao configurar template de índice"

log "Instalação concluída com sucesso!"
log ""
log "Acesse as interfaces:"
log "  - Interface principal: https://logs.gwan.com.br"
log "  - Kibana direto: https://kibana.gwan.com.br"
log "  - Monitoramento: http://localhost:9090"
log ""
log "Credenciais padrão:"
log "  - Usuário: elastic"
log "  - Senha: $ELASTIC_PASSWORD"
log ""
log "Para verificar os logs:"
log "  docker-compose logs -f"
log ""
log "Para parar os serviços:"
log "  docker-compose down"
log ""
log "Para reiniciar os serviços:"
log "  docker-compose restart"
