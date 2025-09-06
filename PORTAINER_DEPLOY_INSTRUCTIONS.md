# Instruções para Deploy no Portainer

## Problema Identificado
O Portainer não tem acesso aos arquivos de configuração do Git, causando erro "is a directory" ao tentar montar volumes.

## Solução: Imagem Customizada

### 1. Construir Imagem Customizada
Execute o script `build-otel-collector.sh` para construir a imagem com configuração embarcada:

```bash
chmod +x build-otel-collector.sh
./build-otel-collector.sh
```

### 2. Fazer Push da Imagem para Registry
Se usando registry privado:

```bash
docker tag gwan-otel-collector:latest seu-registry.com/gwan-otel-collector:latest
docker push seu-registry.com/gwan-otel-collector:latest
```

### 3. Atualizar docker-compose.production.yml
A imagem já está configurada para usar `gwan-otel-collector:latest`.

### 4. Deploy no Portainer
1. Cole o conteúdo do `docker-compose.production.yml`
2. Certifique-se de que a imagem `gwan-otel-collector:latest` está disponível
3. Reinicie a stack

## Vantagens da Solução
- ✅ Não depende de arquivos externos
- ✅ Configuração embarcada na imagem
- ✅ Funciona em qualquer ambiente Docker
- ✅ Elimina problemas de montagem de volumes
- ✅ Mais confiável e portável

## Arquivos Necessários
- `Dockerfile.otel-collector` - Dockerfile para imagem customizada
- `build-otel-collector.sh` - Script para construir a imagem
- `docker-compose.production.yml` - Stack atualizada
