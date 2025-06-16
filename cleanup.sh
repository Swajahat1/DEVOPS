#!/bin/bash

# DevOps Pipeline Cleanup Script
# This script helps clean up Azure resources and local containers

set -e

echo "🧹 DevOps Pipeline Cleanup Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to cleanup Azure resources using Terraform
cleanup_azure_terraform() {
    print_header "Cleaning up Azure resources using Terraform..."
    
    if [ -d "terraform" ] && [ -f "terraform/main.tf" ]; then
        cd terraform
        
        if [ -f "terraform.tfstate" ]; then
            print_status "Found Terraform state. Destroying resources..."
            terraform destroy -auto-approve
            print_status "Azure resources destroyed successfully"
        else
            print_warning "No Terraform state found. Resources may not exist or were already destroyed."
        fi
        
        cd ..
    else
        print_warning "Terraform directory not found. Skipping Terraform cleanup."
    fi
}

# Function to cleanup Azure resources using Azure CLI (alternative)
cleanup_azure_cli() {
    print_header "Alternative: Cleanup using Azure CLI..."
    
    if command -v az &> /dev/null; then
        print_status "Azure CLI found. You can manually delete the resource group:"
        echo "az group delete --name devops-pipeline-rg --yes --no-wait"
        echo ""
        read -p "Do you want to run this command now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            az group delete --name devops-pipeline-rg --yes --no-wait
            print_status "Resource group deletion initiated"
        fi
    else
        print_warning "Azure CLI not found. Please manually delete resources in Azure portal."
    fi
}

# Function to cleanup Docker containers and volumes
cleanup_docker() {
    print_header "Cleaning up Docker containers and volumes..."
    
    # Stop and remove Jenkins container
    if docker ps -a --format 'table {{.Names}}' | grep -q "jenkins-devops-pipeline"; then
        print_status "Stopping and removing Jenkins container..."
        docker stop jenkins-devops-pipeline 2>/dev/null || true
        docker rm jenkins-devops-pipeline 2>/dev/null || true
        print_status "Jenkins container removed"
    else
        print_status "Jenkins container not found"
    fi
    
    # Remove Docker Compose services
    if [ -f "docker-compose.yml" ]; then
        print_status "Stopping Docker Compose services..."
        docker-compose down -v
        print_status "Docker Compose services stopped and volumes removed"
    fi
    
    # Optional: Remove Jenkins volume (WARNING: This will delete all Jenkins data)
    read -p "Do you want to remove Jenkins volume (this will delete all Jenkins data)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume rm jenkins_home 2>/dev/null || true
        print_status "Jenkins volume removed"
    fi
}

# Function to cleanup temporary files
cleanup_temp_files() {
    print_header "Cleaning up temporary files..."
    
    # Remove Terraform state files (optional)
    read -p "Do you want to remove Terraform state files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f terraform/terraform.tfstate*
        rm -f terraform/.terraform.lock.hcl
        rm -rf terraform/.terraform/
        print_status "Terraform state files removed"
    fi
    
    # Remove generated files
    rm -f terraform_output.json
    rm -f inventory.ini
    print_status "Generated files cleaned up"
}

# Main menu
show_menu() {
    echo ""
    print_header "Cleanup Options:"
    echo "1. Cleanup Azure resources (Terraform)"
    echo "2. Cleanup Azure resources (Azure CLI)"
    echo "3. Cleanup Docker containers and volumes"
    echo "4. Cleanup temporary files"
    echo "5. Full cleanup (all of the above)"
    echo "6. Exit"
    echo ""
}

# Main execution
main() {
    while true; do
        show_menu
        read -p "Please select an option (1-6): " choice
        
        case $choice in
            1)
                cleanup_azure_terraform
                ;;
            2)
                cleanup_azure_cli
                ;;
            3)
                cleanup_docker
                ;;
            4)
                cleanup_temp_files
                ;;
            5)
                print_warning "This will perform a full cleanup. Are you sure?"
                read -p "Continue? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cleanup_azure_terraform
                    cleanup_docker
                    cleanup_temp_files
                    print_status "Full cleanup completed! 🧹"
                fi
                ;;
            6)
                print_status "Exiting cleanup script"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-6."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
