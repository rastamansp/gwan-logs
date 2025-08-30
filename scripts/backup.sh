#!/bin/bash

# Script de Backup do Gwan Logs
# Este script faz backup dos dados do Elasticsearch e configurações

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

# Carregar variáveis de ambiente
if [ -f .env ]; then
    source .env
else
    error "Arquivo .env não encontrado"
fi

# Configurações de backup
BACKUP_DIR="/opt/gwan-logs/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="gwan-logs-backup-$DATE"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

log "Iniciando backup do Gwan Logs..."

# Verificar se o Elasticsearch está rodando
if ! docker-compose ps | grep -q "elasticsearch.*Up"; then
    error "Elasticsearch não está rodando"
fi

# Verificar se o Elasticsearch está respondendo
if ! curl -u "elastic:$ELASTIC_PASSWORD" -k "http://localhost:9200/_cluster/health" &> /dev/null; then
    error "Elasticsearch não está respondendo"
fi

# Criar snapshot repository se não existir
log "Configurando repositório de snapshot..."
curl -u "elastic:$ELASTIC_PASSWORD" -X PUT "http://localhost:9200/_snapshot/gwan-backup-repo" \
    -H "Content-Type: application/json" \
    -d '{
        "type": "fs",
        "settings": {
            "location": "/usr/share/elasticsearch/data/backups"
        }
    }' 2>/dev/null || warn "Repositório já existe"

# Criar snapshot
log "Criando snapshot dos dados..."
SNAPSHOT_NAME="snapshot-$DATE"
curl -u "elastic:$ELASTIC_PASSWORD" -X PUT "http://localhost:9200/_snapshot/gwan-backup-repo/$SNAPSHOT_NAME?wait_for_completion=true" \
    -H "Content-Type: application/json" \
    -d '{
        "indices": "gwan-logs-*",
        "ignore_unavailable": true,
        "include_global_state": false
    }' || error "Erro ao criar snapshot"

# Backup das configurações
log "Fazendo backup das configurações..."
CONFIG_BACKUP="$BACKUP_DIR/$BACKUP_NAME-config.tar.gz"
tar -czf "$CONFIG_BACKUP" \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='backups' \
    . || error "Erro ao fazer backup das configurações"

# Backup dos volumes Docker
log "Fazendo backup dos volumes Docker..."
VOLUME_BACKUP="$BACKUP_DIR/$BACKUP_NAME-volumes.tar.gz"
docker run --rm \
    -v gwan-logs-elasticsearch:/elasticsearch \
    -v gwan-logs-kibana:/kibana \
    -v gwan-logs-filebeat:/filebeat \
    -v gwan-logs-logstash:/logstash \
    -v gwan-logs-prometheus:/prometheus \
    -v "$BACKUP_DIR":/backup \
    alpine tar -czf "/backup/$BACKUP_NAME-volumes.tar.gz" \
    /elasticsearch /kibana /filebeat /logstash /prometheus || warn "Erro ao fazer backup dos volumes"

# Backup do snapshot do Elasticsearch
log "Copiando snapshot do Elasticsearch..."
SNAPSHOT_BACKUP="$BACKUP_DIR/$BACKUP_NAME-snapshot.tar.gz"
docker exec gwan-elasticsearch tar -czf "/usr/share/elasticsearch/data/backups/$SNAPSHOT_NAME.tar.gz" \
    -C /usr/share/elasticsearch/data/backups "$SNAPSHOT_NAME" || warn "Erro ao copiar snapshot"

# Copiar snapshot para o host
docker cp "gwan-elasticsearch:/usr/share/elasticsearch/data/backups/$SNAPSHOT_NAME.tar.gz" "$SNAPSHOT_BACKUP" || warn "Erro ao copiar snapshot para host"

# Limpar snapshot temporário
docker exec gwan-elasticsearch rm -rf "/usr/share/elasticsearch/data/backups/$SNAPSHOT_NAME" || true

# Criar arquivo de metadados
log "Criando metadados do backup..."
cat > "$BACKUP_DIR/$BACKUP_NAME-metadata.json" << EOF
{
    "backup_name": "$BACKUP_NAME",
    "date": "$(date -Iseconds)",
    "elasticsearch_version": "$(curl -u "elastic:$ELASTIC_PASSWORD" -s "http://localhost:9200" | jq -r '.version.number')",
    "kibana_version": "$(curl -u "elastic:$ELASTIC_PASSWORD" -s "http://localhost:5601/api/status" | jq -r '.status.overall.version')",
    "indices_backed_up": "$(curl -u "elastic:$ELASTIC_PASSWORD" -s "http://localhost:9200/_cat/indices/gwan-logs-*?format=json" | jq -r '.[].index' | tr '\n' ',')",
    "total_size": "$(du -sh "$BACKUP_DIR/$BACKUP_NAME"* | awk '{sum+=$1} END {print sum}')",
    "hostname": "$(hostname)",
    "docker_version": "$(docker --version)",
    "backup_retention_days": $RETENTION_DAYS
}
EOF

# Verificar integridade dos backups
log "Verificando integridade dos backups..."
for file in "$BACKUP_DIR/$BACKUP_NAME"*.tar.gz; do
    if [ -f "$file" ]; then
        if tar -tzf "$file" >/dev/null 2>&1; then
            log "✓ $file está íntegro"
        else
            error "✗ $file está corrompido"
        fi
    fi
done

# Limpar backups antigos
log "Limpando backups antigos (mais de $RETENTION_DAYS dias)..."
find "$BACKUP_DIR" -name "gwan-logs-backup-*" -type f -mtime +$RETENTION_DAYS -delete

# Calcular tamanho total dos backups
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Tamanho total dos backups: $TOTAL_SIZE"

# Criar relatório de backup
REPORT_FILE="$BACKUP_DIR/$BACKUP_NAME-report.txt"
{
    echo "=== Relatório de Backup Gwan Logs ==="
    echo "Data: $(date)"
    echo "Backup: $BACKUP_NAME"
    echo "Tamanho total: $TOTAL_SIZE"
    echo ""
    echo "Arquivos criados:"
    ls -lh "$BACKUP_DIR/$BACKUP_NAME"*
    echo ""
    echo "Backups retidos:"
    find "$BACKUP_DIR" -name "gwan-logs-backup-*" -type f | wc -l
    echo ""
    echo "Status do Elasticsearch:"
    curl -u "elastic:$ELASTIC_PASSWORD" -s "http://localhost:9200/_cluster/health" | jq '.'
} > "$REPORT_FILE"

log "Backup concluído com sucesso!"
log "Relatório salvo em: $REPORT_FILE"
log "Arquivos de backup em: $BACKUP_DIR"

# Enviar notificação por email se configurado
if [ "$ALERT_EMAIL_ENABLED" = "true" ] && [ -n "$ALERT_EMAIL_RECIPIENTS" ]; then
    log "Enviando notificação por email..."
    {
        echo "Subject: Backup Gwan Logs Concluído"
        echo "From: $ALERT_EMAIL_USERNAME"
        echo "To: $ALERT_EMAIL_RECIPIENTS"
        echo ""
        echo "Backup do Gwan Logs concluído com sucesso!"
        echo "Data: $(date)"
        echo "Backup: $BACKUP_NAME"
        echo "Tamanho: $TOTAL_SIZE"
        echo ""
        echo "Arquivos:"
        ls -lh "$BACKUP_DIR/$BACKUP_NAME"*
    } | sendmail -t || warn "Erro ao enviar email"
fi

log "Backup finalizado!"
