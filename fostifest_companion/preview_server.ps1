$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'build\web')).TrimEnd('\') + '\'
$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add('http://127.0.0.1:43828/')
$listener.Start()
try {
  while ($listener.IsListening) {
    $request = $listener.GetContext()
    try {
      $relative = [Uri]::UnescapeDataString($request.Request.Url.AbsolutePath).TrimStart('/')
      if ([string]::IsNullOrEmpty($relative)) { $relative = 'index.html' }
      $file = [IO.Path]::GetFullPath((Join-Path $root $relative.Replace('/', '\')))
      if (-not $file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists($file)) {
        $request.Response.StatusCode = 404
      } else {
        $types = @{'.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.json'='application/json'; '.wasm'='application/wasm'; '.css'='text/css'; '.png'='image/png'; '.svg'='image/svg+xml'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.woff2'='font/woff2'; '.ttf'='font/ttf'; '.otf'='font/otf'}
        $extension = [IO.Path]::GetExtension($file).ToLowerInvariant()
        $request.Response.ContentType = if ($types.ContainsKey($extension)) { $types[$extension] } else { 'application/octet-stream' }
        $request.Response.Headers['Cache-Control'] = 'no-cache'
        $info = [IO.FileInfo]::new($file)
        $etag = '"{0:x}-{1:x}"' -f $info.Length, $info.LastWriteTimeUtc.Ticks
        $request.Response.Headers['ETag'] = $etag
        if ($request.Request.Headers['If-None-Match'] -eq $etag) {
          $request.Response.StatusCode = 304
        } else {
          $bytes = [IO.File]::ReadAllBytes($file)
          $request.Response.ContentLength64 = $bytes.Length
          if ($request.Request.HttpMethod -ne 'HEAD') { $request.Response.OutputStream.Write($bytes, 0, $bytes.Length) }
        }
      }
    } catch { try { $request.Response.StatusCode = 500 } catch {} }
    finally { try { $request.Response.Close() } catch {} }
  }
} finally { $listener.Close() }
