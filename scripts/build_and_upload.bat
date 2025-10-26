@echo off
REM Script để build và upload release - Windows version
REM Usage: build_and_upload.bat <version>
REM Example: build_and_upload.bat 1.0.1

if "%1"=="" (
    echo Usage: build_and_upload.bat ^<version^>
    echo Example: build_and_upload.bat 1.0.1
    exit /b 1
)

set VERSION=%1

echo.
echo ============================================
echo   Building and Uploading Release v%VERSION%
echo ============================================
echo.

REM Build Android APK
echo [1/4] Building Android APK...
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo Error building Android APK
    exit /b 1
)
echo ✅ Android APK built successfully

echo.
echo [2/4] Building Windows executable...
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo Error building Windows executable
    exit /b 1
)
echo ✅ Windows executable built successfully

echo.
echo [3/4] Uploading Android release to Cloudflare R2...
call dart scripts/upload_release_r2.dart %VERSION% android build\app\outputs\flutter-apk\app-release.apk
if %ERRORLEVEL% neq 0 (
    echo Error uploading Android release
    exit /b 1
)

echo.
echo [4/4] Uploading Windows release to Cloudflare R2...
REM Note: Adjust path if you use a different installer builder
call dart scripts/upload_release_r2.dart %VERSION% windows build\windows\x64\runner\Release\message_app.exe
if %ERRORLEVEL% neq 0 (
    echo Error uploading Windows release
    exit /b 1
)

echo.
echo ============================================
echo   ✅ Release v%VERSION% completed!
echo ============================================
echo.
echo Next steps:
echo 1. Test the auto-update by launching the app
echo 2. Update release notes in Supabase dashboard if needed
echo 3. Announce the update to users
echo.
