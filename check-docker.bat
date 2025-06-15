@echo off
echo Checking if Docker is running...
echo.

:check_loop
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not ready yet. Waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto check_loop
)

echo ✅ Docker is running!
echo.
echo Starting Jenkins container...
docker-compose up -d

if errorlevel 0 (
    echo.
    echo ✅ Jenkins is starting up!
    echo 📱 Access Jenkins at: http://localhost:8080
    echo.
    echo Waiting for Jenkins to be ready...
    timeout /t 30 /nobreak >nul
    echo.
    echo 🎉 Setup complete! Open your browser and go to: http://localhost:8080
) else (
    echo ❌ Failed to start Jenkins
)

pause
