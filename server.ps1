$port = 8000
$url = "http://localhost:$port/"
$path = Get-Location

Write-Host "Starting server at $url"
Write-Host "Serving files from: $path"
Write-Host "Press Ctrl+C to stop the server"
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/" -or $localPath -eq "") {
            $localPath = "/index.html"
        }
        
        $filePath = Join-Path $path ($localPath.TrimStart('/'))
        
        Write-Host "Request: $localPath -> $filePath"
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            
            $response.ContentType = "text/html"
            if ($filePath -like "*.css") { $response.ContentType = "text/css" }
            if ($filePath -like "*.js") { $response.ContentType = "application/javascript" }
            if ($filePath -like "*.png") { $response.ContentType = "image/png" }
            if ($filePath -like "*.jpg" -or $filePath -like "*.jpeg") { $response.ContentType = "image/jpeg" }
            if ($filePath -like "*.svg") { $response.ContentType = "image/svg+xml" }
            
            $response.StatusCode = 200
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
            Write-Host "Served: $localPath (${content.Length} bytes)"
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - File not found: $localPath")
            $response.ContentLength64 = $notFound.Length
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
            Write-Host "404: $localPath"
        }
        
        $response.Close()
    } catch {
        Write-Host "Error: $_"
        if ($response) {
            $response.StatusCode = 500
            $response.Close()
        }
    }
}

