# DevOps Pipeline with Jenkins, Terraform, and Ansible

This project demonstrates a fully automated DevOps pipeline that provisions infrastructure on Azure using Terraform, configures a web server using Ansible, and deploys a static web application.

## 🏗️ Architecture

```
Jenkins (Docker) → Terraform → Azure VM → Ansible → Web Application
```

## 🛠️ Technology Stack

- **Docker**: Containerized Jenkins environment
- **Jenkins**: CI/CD pipeline orchestration
- **Terraform**: Infrastructure as Code (Azure VM provisioning)
- **Ansible**: Configuration management and application deployment
- **Azure**: Cloud infrastructure provider
- **Git**: Version control and source code management

## 📁 Project Structure

```
project/
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Variable definitions
│   └── terraform.tfvars.example   # Example variables file
├── ansible/
│   ├── install_web.yml           # Web server installation playbook
│   └── deploy_app.yml            # Application deployment playbook
├── app/
│   └── index.html                # Static web application
├── Jenkinsfile                   # Jenkins pipeline definition
└── README.md                     # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure Account**: Active Azure subscription
2. **Docker**: Installed on your host machine
3. **SSH Key Pair**: For VM access

### Step 1: Setup Jenkins in Docker

Run Jenkins with required tools:

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which terraform):/usr/local/bin/terraform \
  -v $(which ansible-playbook):/usr/local/bin/ansible-playbook \
  -v $(pwd):/workspace \
  jenkins/jenkins:lts
```

### Step 2: Configure Jenkins

1. Access Jenkins at `http://localhost:8080`
2. Complete initial setup and install suggested plugins
3. Install additional plugins:
   - Git Plugin
   - Pipeline Plugin
   - SSH Agent Plugin

### Step 3: Add Credentials

Add the following credentials in Jenkins (Manage Jenkins → Credentials):

| ID | Type | Description |
|---|---|---|
| `azure-subscription-id` | Secret text | Your Azure subscription ID |
| `azure-client-id` | Secret text | Azure service principal client ID |
| `azure-client-secret` | Secret text | Azure service principal client secret |
| `azure-tenant-id` | Secret text | Your Azure tenant ID |
| `azure-vm-ssh-key` | SSH Username with private key | Private key for VM access |
| `azure-vm-ssh-public-key` | Secret text | Public key for VM access |

### Step 4: Configure Terraform Variables

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`
2. Update the values with your preferences:

```hcl
resource_group_name = "your-devops-pipeline-rg"
location           = "East US"
prefix             = "your-prefix"
vm_size            = "Standard_B1s"
admin_username     = "azureuser"
ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"
```

### Step 5: Create Jenkins Pipeline

1. Create a new Pipeline job in Jenkins
2. Configure it to use this repository
3. Set the pipeline script path to `Jenkinsfile`
4. Run the pipeline

## 🔧 Pipeline Stages

The Jenkins pipeline consists of the following stages:

1. **Checkout**: Retrieves code from the Git repository
2. **Provision VM**: Uses Terraform to create Azure infrastructure
3. **Configure Web Server**: Uses Ansible to install and configure Apache
4. **Deploy Web App**: Uses Ansible to deploy the static web application
5. **Verify Deployment**: Tests the deployed application

## 🔍 Monitoring and Troubleshooting

### Common Issues

1. **SSH Connection Timeout**
   - Ensure your Azure Network Security Group allows SSH (port 22)
   - Verify the SSH key pair is correctly configured

2. **Terraform Authentication Errors**
   - Verify Azure service principal credentials
   - Check Azure subscription permissions

3. **Ansible Connection Issues**
   - Ensure the VM is fully booted before Ansible runs
   - Check SSH key permissions and format

### Logs and Debugging

- Jenkins build logs provide detailed information about each stage
- Terraform state files are stored in the workspace
- Ansible verbose output (`-v`) is enabled for detailed debugging

## 🧹 Cleanup

To avoid Azure charges, clean up resources after testing:

```bash
cd terraform
terraform destroy -auto-approve
```

Or use the Azure CLI:

```bash
az group delete --name your-devops-pipeline-rg --yes --no-wait
```

## 🔒 Security Considerations

- Never commit `terraform.tfvars` or any files containing secrets
- Use Azure Key Vault for production secrets management
- Regularly rotate SSH keys and service principal credentials
- Implement proper network security groups and firewall rules

## 📈 Enhancements

Potential improvements for production use:

- Add automated testing stages
- Implement blue-green deployments
- Add monitoring and alerting
- Use Terraform remote state storage
- Implement proper secret management
- Add infrastructure cost monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Jenkins build logs
3. Check Azure portal for resource status
4. Open an issue in this repository
"# DEVOPS" 
