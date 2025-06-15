#!/bin/bash

# DevOps Pipeline Setup Script
# This script helps set up the Jenkins DevOps pipeline

set -e

echo "🚀 DevOps Pipeline Setup Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_status "Docker is installed"
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_status "Docker is running"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_warning "Terraform is not installed. Jenkins will need Terraform inside the container."
    else
        print_status "Terraform is installed"
    fi
    
    # Check Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        print_warning "Ansible is not installed. Jenkins will need Ansible inside the container."
    else
        print_status "Ansible is installed"
    fi
}

# Generate SSH key pair if not exists
setup_ssh_keys() {
    print_header "Setting up SSH Keys..."
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        print_status "SSH key pair generated"
    else
        print_status "SSH key pair already exists"
    fi
    
    print_status "Your SSH public key:"
    cat ~/.ssh/id_rsa.pub
    echo ""
}

# Setup Terraform variables
setup_terraform_vars() {
    print_header "Setting up Terraform Variables..."
    
    if [ ! -f terraform/terraform.tfvars ]; then
        print_status "Creating terraform.tfvars from example..."
        cp terraform/terraform.tfvars.example terraform/terraform.tfvars
        
        # Get SSH public key
        if [ -f ~/.ssh/id_rsa.pub ]; then
            SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
            # Escape special characters for sed
            SSH_PUBLIC_KEY_ESCAPED=$(echo "$SSH_PUBLIC_KEY" | sed 's/[[\.*^$()+?{|]/\\&/g')
            sed -i "s|ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-email@example.com|$SSH_PUBLIC_KEY_ESCAPED|g" terraform/terraform.tfvars
        fi
        
        print_warning "Please edit terraform/terraform.tfvars with your specific values"
        print_status "terraform.tfvars created"
    else
        print_status "terraform.tfvars already exists"
    fi
}

# Start Jenkins
start_jenkins() {
    print_header "Starting Jenkins..."
    
    # Check if Jenkins container already exists
    if docker ps -a --format 'table {{.Names}}' | grep -q "jenkins-devops-pipeline"; then
        print_status "Jenkins container already exists. Starting it..."
        docker start jenkins-devops-pipeline
    else
        print_status "Creating and starting Jenkins container..."
        docker-compose up -d
    fi
    
    print_status "Jenkins is starting up..."
    print_status "Waiting for Jenkins to be ready..."
    
    # Wait for Jenkins to be ready
    timeout=300
    counter=0
    while [ $counter -lt $timeout ]; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            break
        fi
        sleep 5
        counter=$((counter + 5))
        echo -n "."
    done
    echo ""
    
    if [ $counter -ge $timeout ]; then
        print_error "Jenkins failed to start within $timeout seconds"
        exit 1
    fi
    
    print_status "Jenkins is ready!"
}

# Display next steps
show_next_steps() {
    print_header "Next Steps:"
    echo ""
    echo "1. Access Jenkins at: http://localhost:8080"
    echo "2. Complete the initial setup wizard"
    echo "3. Install required plugins: Git, Pipeline, SSH Agent"
    echo "4. Add Azure credentials in Jenkins:"
    echo "   - azure-subscription-id"
    echo "   - azure-client-id" 
    echo "   - azure-client-secret"
    echo "   - azure-tenant-id"
    echo "   - azure-vm-ssh-key (private key)"
    echo "   - azure-vm-ssh-public-key (public key)"
    echo "5. Edit terraform/terraform.tfvars with your values"
    echo "6. Create a new Pipeline job pointing to this repository"
    echo "7. Run the pipeline!"
    echo ""
    print_status "Setup completed successfully! 🎉"
}

# Main execution
main() {
    check_prerequisites
    setup_ssh_keys
    setup_terraform_vars
    start_jenkins
    show_next_steps
}

# Run main function
main
