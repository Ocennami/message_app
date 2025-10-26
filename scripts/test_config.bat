@echo off
REM Quick test script - Check if config is setup correctly
REM Usage: test_config.bat

echo.
echo ============================================
echo   Testing Auto-Update Configuration
echo ============================================
echo.

echo [1/3] Checking auto_update_config.dart...
if not exist "lib\config\auto_update_config.dart" (
    echo ❌ File not found: lib\config\auto_update_config.dart
    echo Please create it from auto_update_config.dart.template
    exit /b 1
)
echo ✅ Config file exists

echo.
echo [2/3] Checking if Service Role Key is set...
findstr /C:"YOUR_SUPABASE_SERVICE_ROLE_KEY" "lib\config\auto_update_config.dart" >nul
if %ERRORLEVEL% equ 0 (
    echo ❌ Service Role Key not configured!
    echo Please edit lib\config\auto_update_config.dart
    exit /b 1
)
echo ✅ Service Role Key configured

echo.
echo [3/3] Checking Supabase bucket...
echo ℹ️  Manually verify that bucket 'releases' exists in Supabase Storage
echo    Dashboard → Storage → Buckets → releases
echo.

echo.
echo ============================================
echo   ✅ Configuration looks good!
echo ============================================
echo.
echo Ready to upload releases!
echo.
echo Try:
echo   scripts\build_and_upload.bat 1.0.0
echo.
