@echo off
echo 🚀 Starting Jenkins for DevOps Pipeline...
echo.

echo Stopping any existing Jenkins containers...
docker stop jenkins-devops-pipeline 2>nul
docker rm jenkins-devops-pipeline 2>nul

echo.
echo Starting Jenkins container...
docker run -d ^
  --name jenkins-devops-pipeline ^
  -p 8080:8080 ^
  -p 50000:50000 ^
  -v jenkins_home:/var/jenkins_home ^
  -v "%cd%":/workspace ^
  jenkins/jenkins:lts

if errorlevel 0 (
    echo.
    echo ✅ Jenkins container started successfully!
    echo.
    echo 📱 Jenkins will be available at: http://localhost:8080
    echo.
    echo Waiting for Jenkins to start up...
    timeout /t 30 /nobreak >nul
    echo.
    echo 🎉 Jenkins should be ready now!
    echo 🌐 Opening Jenkins in your browser...
    start http://localhost:8080
) else (
    echo ❌ Failed to start Jenkins container
    echo Please check Docker Desktop is running
)

echo.
echo To get the initial admin password, run:
echo docker exec jenkins-devops-pipeline cat /var/jenkins_home/secrets/initialAdminPassword
echo.
pause
