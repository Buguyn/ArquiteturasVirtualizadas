<#
.DESCRIPTION
    Realiza teste de carga nos servidores usando Apache Benchmark
#>

# Verifica se o Apache Benchmark está instalado
if (-not (Test-Path "C:\Program Files (x86)\Apache Software Foundation\Apache24\bin\ab.exe")) {
    Write-Host "Instalando Apache Benchmark..."
    choco install apache-httpd -y --force
}

$servers = @(
    @{Name="Ubuntu"; URL="http://192.168.1.100:5000/api/data"},
    @{Name="Debian"; URL="http://192.168.1.101:5000/api/data"},
    @{Name="Windows10"; URL="http://192.168.1.102:5000/api/data"}
)

$resultsDir = "load_test_results"
if (-not (Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir
}

foreach ($server in $servers) {
    $outputFile = "$resultsDir\$($server.Name)_load_test.txt"
    
    Write-Host "Testando $($server.Name)..."
    & "C:\Program Files (x86)\Apache Software Foundation\Apache24\bin\ab.exe" -n 1000 -c 50 $($server.URL) | Out-File -FilePath $outputFile
    
    # Extrai métricas principais
    $content = Get-Content $outputFile
    $requestsPerSecond = ($content | Select-String "Requests per second:" -Context 0,1).ToString().Split(":")[1].Trim()
    $timePerRequest = ($content | Select-String "Time per request:" -Context 0,2)[0].ToString().Split(":")[1].Trim()
    
    [PSCustomObject]@{
        Server = $server.Name
        RequestsPerSecond = $requestsPerSecond
        TimePerRequest = $timePerRequest
        ResultFile = $outputFile
    } | Format-Table -AutoSize
}

Write-Host "Todos os testes concluídos! Verifique os arquivos em $resultsDir"