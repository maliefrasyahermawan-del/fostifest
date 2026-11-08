param([switch]$NoOpen)
$ErrorActionPreference = 'Stop'
$previewUrl = 'http://127.0.0.1:43827/'
$projectDirectory = $PSScriptRoot
$indexFile = Join-Path $projectDirectory 'build\web\index.html'
$serverScript = Join-Path $projectDirectory 'preview_server.ps1'

function Test-PreviewReady {
  try {
    $response = Invoke-WebRequest -Uri $previewUrl -UseBasicParsing -TimeoutSec 2
    return $response.StatusCode -eq 200 -and $response.Content.Contains('<title>LARAS UMKM Preview</title>')
  } catch { return $false }
}

$sources = @(Get-ChildItem -LiteralPath (Join-Path $projectDirectory 'lib') -Filter '*.dart' -Recurse -File)
$sources += @(Get-ChildItem -LiteralPath (Join-Path $projectDirectory 'web') -Recurse -File)
$sources += Get-Item -LiteralPath (Join-Path $projectDirectory 'pubspec.yaml')
$needsBuild = -not (Test-Path -LiteralPath $indexFile)
if (-not $needsBuild) {
  $builtAt = (Get-Item -LiteralPath $indexFile).LastWriteTimeUtc
  $needsBuild = @($sources | Where-Object { $_.LastWriteTimeUtc -gt $builtAt }).Count -gt 0
}
if ($needsBuild) {
  $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
  if (-not $flutterCommand) { Write-Host 'Flutter tidak ditemukan di PATH.'; exit 1 }
  Write-Host 'Menyiapkan preview ringan. Proses ini hanya diperlukan saat kode berubah dan dapat memerlukan beberapa menit.'
  Push-Location $projectDirectory
  try { & $flutterCommand.Source build web --release -O1 --no-wasm-dry-run; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
  finally { Pop-Location }
}

if (-not (Test-PreviewReady)) {
  Write-Host 'Menyalakan preview lokal...'
  $server = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $serverScript)) -WorkingDirectory $projectDirectory -WindowStyle Hidden -PassThru
  $deadline = (Get-Date).AddSeconds(30)
  while ((Get-Date) -lt $deadline -and -not (Test-PreviewReady)) {
    $server.Refresh()
    if ($server.HasExited) { Write-Host 'Preview gagal dimulai. Pastikan port 43827 tidak digunakan aplikasi lain.'; exit 1 }
    Start-Sleep -Milliseconds 500
  }
}
if (-not (Test-PreviewReady)) { Write-Host 'Preview belum dapat dibuka. Pastikan port 43827 tersedia.'; exit 1 }
if (-not $NoOpen) { Start-Process $previewUrl; Write-Host 'Preview LARAS dibuka di browser.' }
else { Write-Host "Preview LARAS siap di $previewUrl" }
