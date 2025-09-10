# Downloads Firebase C++ SDK base and Firestore zips for Windows and extracts them
# into build/windows/x64/extracted so Flutter Windows build can link required libs.

param(
  [string]$Version = "12.7.0"
)

$ErrorActionPreference = 'Stop'

$baseUrl = "https://dl.google.com/firebase/sdk/cpp"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$downloadsDir = "build/windows/x64/downloads_$timestamp"
$extractDir = "build/windows/x64/extracted"

if (Test-Path $downloadsDir) {
  Write-Host "Clearing existing $downloadsDir"
  Remove-Item -Recurse -Force $downloadsDir
}
New-Item -Force -ItemType Directory $downloadsDir | Out-Null

$files = @(
  "firebase_cpp_sdk_windows_${Version}.zip",
  "firebase_cpp_sdk_windows_${Version}_firestore.zip"
)

foreach ($f in $files) {
  $uri = "$baseUrl/$f"
  $outFile = Join-Path $downloadsDir $f
  Write-Host "Downloading $uri -> $outFile"
  if (Test-Path $outFile) { Remove-Item -Force $outFile }
  Invoke-WebRequest -Uri $uri -OutFile $outFile -UseBasicParsing
}

if (Test-Path $extractDir) {
  Write-Host "Removing existing $extractDir"
  Remove-Item -Recurse -Force $extractDir
}

New-Item -Force -ItemType Directory $extractDir | Out-Null

foreach ($f in $files) {
  $zipPath = Join-Path $downloadsDir $f
  Write-Host "Extracting $zipPath -> $extractDir"
  Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
}

Write-Host "Done. Extracted to $extractDir"
