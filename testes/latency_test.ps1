<#
.DESCRIPTION
    Testa o tempo de resposta de todos os servidores
#>

$servers = @(
    "http://192.168.1.100:5000/api/data",  # Ubuntu
    "http://192.168.1.101:5000/api/data",  # Debian
    "http://192.168.1.102:5000/api/data"   # Windows 10
)

$results = @()

# Testa cada servidor 10 vezes
1..10 | ForEach-Object {
    $testResult = [PSCustomObject]@{
        Iteration = $_
    }
    
    foreach ($server in $servers) {
        $measurement = Measure-Command {
            try {
                Invoke-RestMethod -Uri $server -Method Get -ErrorAction Stop | Out-Null
            } catch {
                Write-Warning "Falha ao acessar $server"
            }
        }
        $testResult | Add-Member -NotePropertyName $server -NotePropertyValue $measurement.TotalMilliseconds
    }
    
    $results += $testResult
}

# Exibe resultados
$results | Format-Table -AutoSize

# Exporta para CSV
$results | Export-Csv -Path "latency_results.csv" -NoTypeInformation
Write-Host "Resultados salvos em latency_results.csv"