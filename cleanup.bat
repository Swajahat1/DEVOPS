@echo off
setlocal enabledelayedexpansion

echo.
echo 🧹 DevOps Pipeline Cleanup Script
echo ==================================
echo.

:menu
echo Cleanup Options:
echo 1. Cleanup Azure resources (Terraform)
echo 2. Cleanup Docker containers and volumes
echo 3. Cleanup temporary files
echo 4. Full cleanup (all of the above)
echo 5. Exit
echo.

set /p choice="Please select an option (1-5): "

if "%choice%"=="1" goto terraform_cleanup
if "%choice%"=="2" goto docker_cleanup
if "%choice%"=="3" goto temp_cleanup
if "%choice%"=="4" goto full_cleanup
if "%choice%"=="5" goto exit
echo [ERROR] Invalid option. Please select 1-5.
goto menu

:terraform_cleanup
echo.
echo [INFO] Cleaning up Azure resources using Terraform...
if exist "terraform\main.tf" (
    cd terraform
    if exist "terraform.tfstate" (
        echo [INFO] Found Terraform state. Destroying resources...
        terraform destroy -auto-approve
        echo [INFO] Azure resources destroyed successfully
    ) else (
        echo [WARNING] No Terraform state found. Resources may not exist or were already destroyed.
    )
    cd ..
) else (
    echo [WARNING] Terraform directory not found. Skipping Terraform cleanup.
)
goto menu

:docker_cleanup
echo.
echo [INFO] Cleaning up Docker containers and volumes...

REM Stop and remove Jenkins container
docker ps -a --format "table {{.Names}}" | findstr "jenkins-devops-pipeline" >nul
if not errorlevel 1 (
    echo [INFO] Stopping and removing Jenkins container...
    docker stop jenkins-devops-pipeline >nul 2>&1
    docker rm jenkins-devops-pipeline >nul 2>&1
    echo [INFO] Jenkins container removed
) else (
    echo [INFO] Jenkins container not found
)

REM Remove Docker Compose services
if exist "docker-compose.yml" (
    echo [INFO] Stopping Docker Compose services...
    docker-compose down -v
    echo [INFO] Docker Compose services stopped and volumes removed
)

REM Optional: Remove Jenkins volume
set /p remove_volume="Do you want to remove Jenkins volume (this will delete all Jenkins data)? (y/N): "
if /i "%remove_volume%"=="y" (
    docker volume rm jenkins_home >nul 2>&1
    echo [INFO] Jenkins volume removed
)
goto menu

:temp_cleanup
echo.
echo [INFO] Cleaning up temporary files...

REM Remove Terraform state files (optional)
set /p remove_state="Do you want to remove Terraform state files? (y/N): "
if /i "%remove_state%"=="y" (
    if exist "terraform\terraform.tfstate" del "terraform\terraform.tfstate" >nul 2>&1
    if exist "terraform\terraform.tfstate.backup" del "terraform\terraform.tfstate.backup" >nul 2>&1
    if exist "terraform\.terraform.lock.hcl" del "terraform\.terraform.lock.hcl" >nul 2>&1
    if exist "terraform\.terraform" rmdir /s /q "terraform\.terraform" >nul 2>&1
    echo [INFO] Terraform state files removed
)

REM Remove generated files
if exist "terraform_output.json" del "terraform_output.json" >nul 2>&1
if exist "inventory.ini" del "inventory.ini" >nul 2>&1
echo [INFO] Generated files cleaned up
goto menu

:full_cleanup
echo.
echo [WARNING] This will perform a full cleanup. Are you sure?
set /p confirm="Continue? (y/N): "
if /i "%confirm%"=="y" (
    call :terraform_cleanup_silent
    call :docker_cleanup_silent
    call :temp_cleanup_silent
    echo [INFO] Full cleanup completed! 🧹
)
goto menu

:terraform_cleanup_silent
if exist "terraform\main.tf" (
    cd terraform
    if exist "terraform.tfstate" (
        terraform destroy -auto-approve >nul 2>&1
    )
    cd ..
)
exit /b

:docker_cleanup_silent
docker stop jenkins-devops-pipeline >nul 2>&1
docker rm jenkins-devops-pipeline >nul 2>&1
if exist "docker-compose.yml" docker-compose down -v >nul 2>&1
exit /b

:temp_cleanup_silent
if exist "terraform\terraform.tfstate" del "terraform\terraform.tfstate" >nul 2>&1
if exist "terraform\terraform.tfstate.backup" del "terraform\terraform.tfstate.backup" >nul 2>&1
if exist "terraform\.terraform.lock.hcl" del "terraform\.terraform.lock.hcl" >nul 2>&1
if exist "terraform\.terraform" rmdir /s /q "terraform\.terraform" >nul 2>&1
if exist "terraform_output.json" del "terraform_output.json" >nul 2>&1
if exist "inventory.ini" del "inventory.ini" >nul 2>&1
exit /b

:exit
echo [INFO] Exiting cleanup script
pause
exit /b 0
