# 🔍 Script de Verificação de Telemetria - Gwan APM (PowerShell)
# Este script verifica se a telemetria está sendo recebida corretamente

Write-Host "🚀 Iniciando verificação de telemetria do Gwan APM..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Função para verificar se um serviço está respondendo
function Test-Service {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$ExpectedStatus = 200
    )
    
    Write-Host "🔍 Verificando $ServiceName... " -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "✅ OK" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ FALHOU (Status: $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ FALHOU ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

# Função para verificar métricas
function Test-Metrics {
    param(
        [string]$MetricName,
        [string]$Description
    )
    
    Write-Host "📊 Verificando $Description... " -NoNewline
    
    try {
        $metricsResponse = Invoke-WebRequest -Uri "http://gwan.com.br:8888/metrics" -UseBasicParsing
        $metricsContent = $metricsResponse.Content
        
        $metricLine = $metricsContent | Select-String $MetricName | Select-Object -First 1
        if ($metricLine) {
            $value = ($metricLine.Line -split '\s+')[1]
            if ($value -and $value -ne "0") {
                Write-Host "✅ OK (valor: $value)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️  Sem dados (valor: $value)" -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "⚠️  Métrica não encontrada" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "❌ FALHOU ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "🔧 1. Verificação de Serviços" -ForegroundColor Blue
Write-Host "==============================" -ForegroundColor Blue

# Verificar serviços principais
Test-Service "OTEL Collector Health" "http://gwan.com.br:13133/"
Test-Service "Jaeger" "http://gwan.com.br:16687/"
Test-Service "Kibana" "http://gwan.com.br:5602/"
Test-Service "Prometheus" "http://gwan.com.br:9091/"
Test-Service "Alertmanager" "http://gwan.com.br:9094/"

Write-Host ""
Write-Host "📊 2. Verificação de Métricas" -ForegroundColor Blue
Write-Host "============================" -ForegroundColor Blue

# Verificar métricas do OTEL Collector
Test-Metrics "otelcol_receiver_accepted_spans_total" "Traces recebidos"
Test-Metrics "otelcol_receiver_accepted_log_records_total" "Logs recebidos"
Test-Metrics "otelcol_receiver_accepted_metric_points_total" "Métricas recebidas"

Write-Host ""
Write-Host "🧪 3. Teste de Envio de Telemetria" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue

Write-Host "📤 Enviando trace de teste... " -NoNewline

# Enviar trace de teste
$tracePayload = @{
    resourceSpans = @(
        @{
            resource = @{
                attributes = @(
                    @{
                        key = "service.name"
                        value = @{ stringValue = "test-service-script" }
                    }
                )
            }
            scopeSpans = @(
                @{
                    scope = @{ name = "test-scope" }
                    spans = @(
                        @{
                            traceId = "12345678901234567890123456789012"
                            spanId = "1234567890123456"
                            name = "test-span-script"
                            kind = "SPAN_KIND_INTERNAL"
                            startTimeUnixNano = "1640995200000000000"
                            endTimeUnixNano = "1640995201000000000"
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $traceResponse = Invoke-WebRequest -Uri "http://gwan.com.br:4318/v1/traces" -Method Post -Body $tracePayload -ContentType "application/json" -UseBasicParsing
    if ($traceResponse.StatusCode -eq 200) {
        Write-Host "✅ OK" -ForegroundColor Green
    } else {
        Write-Host "❌ FALHOU" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ FALHOU ($($_.Exception.Message))" -ForegroundColor Red
}

Write-Host "📤 Enviando log de teste... " -NoNewline

# Enviar log de teste
$logPayload = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{
                        key = "service.name"
                        value = @{ stringValue = "test-service-script" }
                    }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{ name = "test-scope" }
                    logRecords = @(
                        @{
                            timeUnixNano = "1640995200000000000"
                            severityNumber = 9
                            severityText = "INFO"
                            body = @{ stringValue = "Test log message from script" }
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $logResponse = Invoke-WebRequest -Uri "http://gwan.com.br:4318/v1/logs" -Method Post -Body $logPayload -ContentType "application/json" -UseBasicParsing
    if ($logResponse.StatusCode -eq 200) {
        Write-Host "✅ OK" -ForegroundColor Green
    } else {
        Write-Host "❌ FALHOU" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ FALHOU ($($_.Exception.Message))" -ForegroundColor Red
}

Write-Host ""
Write-Host "⏳ Aguardando 5 segundos para processamento..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "🔍 4. Verificação Pós-Teste" -ForegroundColor Blue
Write-Host "===========================" -ForegroundColor Blue

# Verificar se os dados de teste chegaram
Test-Metrics "otelcol_receiver_accepted_spans_total" "Traces recebidos (pós-teste)"
Test-Metrics "otelcol_receiver_accepted_log_records_total" "Logs recebidos (pós-teste)"

Write-Host ""
Write-Host "📋 5. URLs para Verificação Manual" -ForegroundColor Blue
Write-Host "===================================" -ForegroundColor Blue

Write-Host "🔍 Jaeger: http://jaeger.gwan.com.br/ ou http://gwan.com.br:16687/" -ForegroundColor Cyan
Write-Host "📊 Kibana: http://kibana.gwan.com.br/ ou http://gwan.com.br:5602/" -ForegroundColor Cyan
Write-Host "📈 Prometheus: http://prometheus.gwan.com.br/ ou http://gwan.com.br:9091/" -ForegroundColor Cyan
Write-Host "🚨 Alertmanager: http://alertmanager.gwan.com.br/ ou http://gwan.com.br:9094/" -ForegroundColor Cyan

Write-Host ""
Write-Host "💡 Dicas:" -ForegroundColor Yellow
Write-Host "==========" -ForegroundColor Yellow
Write-Host "• Procure por 'test-service-script' no Jaeger" -ForegroundColor White
Write-Host "• Procure por 'test-service-script' no Kibana Discover" -ForegroundColor White
Write-Host "• Verifique as métricas no Prometheus" -ForegroundColor White
Write-Host "• Consulte os logs dos containers se houver problemas" -ForegroundColor White

Write-Host ""
Write-Host "✅ Verificação concluída!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
