@echo off
echo ===================================================
echo      Starting SWSAS (SafeHer AI) Environment       
echo ===================================================

echo [1/3] Launching Android Emulator...
start cmd /c "cd backend\swsas_frontend && flutter emulators --launch Medium_Phone_API_35"

:: Wait a few seconds to let the emulator boot process begin
timeout /t 5 /nobreak >nul

echo [2/3] Starting FastAPI Backend Data Server...
start "SWSAS Backend Server" cmd /k "cd backend && call run.bat"

echo [3/3] Starting Flutter Frontend App...
echo Note: This window will stay open to show flutter logs.
cd backend\swsas_frontend
flutter run -d emulator-5554
