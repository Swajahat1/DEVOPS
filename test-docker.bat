@echo off
echo 🔧 Testing Docker...
echo.

echo Testing Docker with hello-world...
docker run hello-world

if errorlevel 0 (
    echo.
    echo ✅ Docker is working!
    echo.
    echo 🚀 Starting Jenkins...
    docker run -d --name jenkins-devops-pipeline -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
    
    if errorlevel 0 (
        echo ✅ Jenkins container started!
        echo.
        echo 📱 Jenkins will be available at: http://localhost:8080
        echo ⏳ Waiting 30 seconds for Jenkins to start...
        timeout /t 30 /nobreak
        echo.
        echo 🌐 Opening Jenkins...
        start http://localhost:8080
        echo.
        echo To get admin password, run:
        echo docker exec jenkins-devops-pipeline cat /var/jenkins_home/secrets/initialAdminPassword
    ) else (
        echo ❌ Failed to start Jenkins
    )
) else (
    echo ❌ Docker is not working properly
    echo Please restart Docker Desktop and try again
)

pause
