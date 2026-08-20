param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeBaseId,
    [string]$DatasetDirectory = "resources/test-data/performance/documents",
    [int]$MaxDocuments = 50,
    [int]$SkipDocuments = 0,
    [int]$ChunkSize = 48,
    [int]$OverlapSize = 8,
    [string]$BaseUrl = "http://127.0.0.1:9090/api/ragent",
    [string]$OutputFile = "resources/test-data/performance/real-ingestion-results.json"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

function Invoke-ApiJson {
    param([string]$Uri, [string]$Method = "GET", [hashtable]$Headers = @{}, [object]$Body = $null)
    $params = @{ Uri = $Uri; Method = $Method; Headers = $Headers; TimeoutSec = 30 }
    if ($null -ne $Body) {
        $params.ContentType = "application/json"
        $params.Body = $Body | ConvertTo-Json -Compress -Depth 8
    }
    $response = Invoke-RestMethod @params
    if (-not $response.success) {
        throw "API failed: $($response.message)"
    }
    return $response.data
}

function Send-Document {
    param([string]$FilePath, [string]$KbId, [string]$Token)
    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromSeconds(60)
    $client.DefaultRequestHeaders.Add("Authorization", $Token)
    $form = [System.Net.Http.MultipartFormDataContent]::new()
    $stream = [System.IO.File]::OpenRead($FilePath)
    try {
        $fileContent = [System.Net.Http.StreamContent]::new($stream)
        $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("text/markdown")
        $form.Add($fileContent, "file", [System.IO.Path]::GetFileName($FilePath))
        $form.Add([System.Net.Http.StringContent]::new("file"), "sourceType")
        $form.Add([System.Net.Http.StringContent]::new("chunk"), "processMode")
        $form.Add([System.Net.Http.StringContent]::new("fixed_size"), "chunkStrategy")
        $config = "{`"chunkSize`":$ChunkSize,`"overlapSize`":$OverlapSize}"
        $form.Add([System.Net.Http.StringContent]::new($config), "chunkConfig")
        $response = $client.PostAsync("$BaseUrl/knowledge-base/$KbId/docs/upload", $form).GetAwaiter().GetResult()
        $payload = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        if (-not $payload.success) {
            throw "Upload failed: $($payload.message)"
        }
        return $payload.data
    } finally {
        $stream.Dispose()
        $form.Dispose()
        $client.Dispose()
    }
}

function Get-Percentile {
    param([long[]]$Values, [double]$Percentile)
    if ($Values.Count -eq 0) { return 0 }
    $sorted = $Values | Sort-Object
    $index = [Math]::Ceiling($Percentile * $sorted.Count) - 1
    return $sorted[[Math]::Max(0, $index)]
}

$login = Invoke-ApiJson -Uri "$BaseUrl/auth/login" -Method POST -Body @{ username = "admin"; password = "admin" }
$headers = @{ Authorization = $login.token }
$files = Get-ChildItem (Resolve-Path $DatasetDirectory) -Filter *.md -File |
    Sort-Object Name | Select-Object -Skip $SkipDocuments -First $MaxDocuments
$results = [System.Collections.Generic.List[object]]::new()
$suiteStart = Get-Date

for ($index = 0; $index -lt $files.Count; $index++) {
    $file = $files[$index]
    $doc = Send-Document -FilePath $file.FullName -KbId $KnowledgeBaseId -Token $login.token
    Invoke-ApiJson -Uri "$BaseUrl/knowledge-base/docs/$($doc.id)/chunk" -Method POST -Headers $headers | Out-Null

    $deadline = (Get-Date).AddMinutes(3)
    do {
        Start-Sleep -Seconds 1
        $current = Invoke-ApiJson -Uri "$BaseUrl/knowledge-base/docs/$($doc.id)" -Headers $headers
    } while ($current.status -in @("pending", "running") -and (Get-Date) -lt $deadline)

    $logs = Invoke-ApiJson -Uri "$BaseUrl/knowledge-base/docs/$($doc.id)/chunk-logs?current=1&size=1" -Headers $headers
    $latest = $logs.records | Select-Object -First 1
    $result = [ordered]@{
        file = $file.Name
        docId = $doc.id
        status = $current.status
        fileSize = $doc.fileSize
        chunkCount = $current.chunkCount
        extractDurationMs = $latest.extractDuration
        chunkDurationMs = $latest.chunkDuration
        embedDurationMs = $latest.embedDuration
        persistDurationMs = $latest.persistDuration
        totalDurationMs = $latest.totalDuration
        error = $latest.errorMessage
    }
    $results.Add($result)
    Write-Output ("[{0}/{1}] {2}: status={3}, chunks={4}, embed={5}ms, total={6}ms" -f
        ($index + 1), $files.Count, $file.Name, $result.status, $result.chunkCount,
        $result.embedDurationMs, $result.totalDurationMs)
}

$successful = @($results | Where-Object { $_.status -eq "success" })
$embedTimes = @($successful | ForEach-Object { [long]$_.embedDurationMs })
$totalTimes = @($successful | ForEach-Object { [long]$_.totalDurationMs })
$totalChunks = ($successful | ForEach-Object { [long]$_['chunkCount'] } | Measure-Object -Sum).Sum
$elapsedSeconds = [Math]::Round(((Get-Date) - $suiteStart).TotalSeconds, 2)
$report = [ordered]@{
    generatedAt = (Get-Date).ToString("s")
    knowledgeBaseId = $KnowledgeBaseId
    configuration = @{ chunkSize = $ChunkSize; overlapSize = $OverlapSize; maxBatchSize = 32; maxBatchConcurrency = 4 }
    summary = [ordered]@{
        documentCount = $files.Count
        successCount = $successful.Count
        failureCount = $files.Count - $successful.Count
        totalChunks = $totalChunks
        elapsedSeconds = $elapsedSeconds
        embeddingAverageMs = if ($embedTimes.Count) { [Math]::Round(($embedTimes | Measure-Object -Average).Average, 2) } else { 0 }
        embeddingP50Ms = Get-Percentile -Values $embedTimes -Percentile 0.50
        embeddingP95Ms = Get-Percentile -Values $embedTimes -Percentile 0.95
        totalAverageMs = if ($totalTimes.Count) { [Math]::Round(($totalTimes | Measure-Object -Average).Average, 2) } else { 0 }
        totalP95Ms = Get-Percentile -Values $totalTimes -Percentile 0.95
        chunksPerSecond = if ($elapsedSeconds -gt 0) { [Math]::Round($totalChunks / $elapsedSeconds, 2) } else { 0 }
    }
    results = $results
}

$parent = Split-Path -Parent $OutputFile
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputFile -Encoding UTF8
$report.summary | ConvertTo-Json -Depth 5
