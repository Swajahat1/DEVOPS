@echo off
setlocal enabledelayedexpansion

echo.
echo 🚀 DevOps Pipeline Setup Script
echo ================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)
echo [INFO] Docker is installed

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo [INFO] Docker is running

REM Setup Terraform variables
echo.
echo Setting up Terraform Variables...
if not exist "terraform\terraform.tfvars" (
    echo [INFO] Creating terraform.tfvars from example...
    copy "terraform\terraform.tfvars.example" "terraform\terraform.tfvars" >nul
    echo [WARNING] Please edit terraform\terraform.tfvars with your specific values
    echo [INFO] terraform.tfvars created
) else (
    echo [INFO] terraform.tfvars already exists
)

REM Start Jenkins
echo.
echo Starting Jenkins...

REM Check if Jenkins container already exists
docker ps -a --format "table {{.Names}}" | findstr "jenkins-devops-pipeline" >nul
if not errorlevel 1 (
    echo [INFO] Jenkins container already exists. Starting it...
    docker start jenkins-devops-pipeline
) else (
    echo [INFO] Creating and starting Jenkins container...
    docker-compose up -d
)

echo [INFO] Jenkins is starting up...
echo [INFO] Waiting for Jenkins to be ready...

REM Wait for Jenkins to be ready (simplified for Windows)
timeout /t 30 /nobreak >nul
echo [INFO] Jenkins should be ready now!

echo.
echo Next Steps:
echo ===========
echo.
echo 1. Access Jenkins at: http://localhost:8080
echo 2. Complete the initial setup wizard
echo 3. Install required plugins: Git, Pipeline, SSH Agent
echo 4. Add Azure credentials in Jenkins:
echo    - azure-subscription-id
echo    - azure-client-id
echo    - azure-client-secret
echo    - azure-tenant-id
echo    - azure-vm-ssh-key (private key)
echo    - azure-vm-ssh-public-key (public key)
echo 5. Edit terraform\terraform.tfvars with your values
echo 6. Create a new Pipeline job pointing to this repository
echo 7. Run the pipeline!
echo.
echo [INFO] Setup completed successfully! 🎉
echo.
pause
