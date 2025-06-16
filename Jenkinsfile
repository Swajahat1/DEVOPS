pipeline {
    agent any

    environment {
        AZURE_SUBSCRIPTION_ID = credentials('3e47ba0e-8067-42b7-bda9-33f85d9d39a5 ')
        AZURE_CLIENT_ID = credentials('1d1775eb-7ca9-4356-a242-aee191fc4d20')
        AZURE_CLIENT_SECRET = credentials('71384082-b5c5-4ae8-acd5-af0822a95dc7')
        AZURE_TENANT_ID = credentials('78a31f2f-a764-4a56-a3b9-832c487e790b')
        SSH_KEY = credentials('azureuser')
        TF_VAR_ssh_public_key = credentials('azure-vm-ssh-public-key')
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_STDOUT_CALLBACK = 'yaml'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Provision VM') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "Initializing Terraform..."
                        terraform init

                        echo "Planning Terraform deployment..."
                        terraform plan -out=tfplan

                        echo "Applying Terraform configuration..."
                        terraform apply -auto-approve tfplan

                        echo "Extracting Terraform outputs..."
                        terraform output -json > ../terraform_output.json

                        echo "Terraform outputs:"
                        cat ../terraform_output.json
                    '''
                }
            }
        }
        
        stage('Configure Web Server') {
            steps {
                script {
                    def tfOutput = readJSON file: 'terraform_output.json'
                    def vmIP = tfOutput.vm_public_ip.value

                    echo "VM Public IP: ${vmIP}"

                    // Create dynamic inventory for Ansible
                    writeFile file: 'inventory.ini', text: "[webserver]\n${vmIP} ansible_user=azureuser ansible_ssh_private_key_file=${SSH_KEY} ansible_ssh_common_args='-o StrictHostKeyChecking=no'"

                    echo "Created Ansible inventory:"
                    sh 'cat inventory.ini'

                    // Wait for SSH to be available
                    sh """
                        echo "Waiting for SSH to be available on ${vmIP}..."
                        timeout 300 bash -c 'until nc -z ${vmIP} 22; do sleep 5; done'
                        echo "SSH is now available!"
                    """

                    sh 'ansible-playbook -i inventory.ini ansible/install_web.yml -v'
                }
            }
        }
        
        stage('Deploy Web App') {
            steps {
                sh 'ansible-playbook -i inventory.ini ansible/deploy_app.yml -v'
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    def tfOutput = readJSON file: 'terraform_output.json'
                    def vmIP = tfOutput.vm_public_ip.value

                    echo "Verifying deployment at http://${vmIP}"

                    // Wait for web server to be ready
                    sh """
                        echo "Waiting for web server to be ready..."
                        timeout 120 bash -c 'until curl -s http://${vmIP} > /dev/null; do sleep 5; done'
                        echo "Web server is responding!"
                    """

                    // Verify the content
                    sh """
                        echo "Testing web application..."
                        curl -s http://${vmIP} | grep -i 'welcome' || (echo "Verification failed!" && exit 1)
                        echo "✅ Deployment verification successful!"
                        echo "🌐 Application is available at: http://${vmIP}"
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed.'
            // Archive terraform outputs for debugging
            archiveArtifacts artifacts: 'terraform_output.json, inventory.ini', allowEmptyArchive: true
        }
        success {
            script {
                if (fileExists('terraform_output.json')) {
                    def tfOutput = readJSON file: 'terraform_output.json'
                    def vmIP = tfOutput.vm_public_ip.value
                    echo "🎉 Pipeline completed successfully!"
                    echo "🌐 Your application is available at: http://${vmIP}"
                    echo "🔗 SSH access: ${tfOutput.ssh_connection_command.value}"
                }
            }
        }
        failure {
            echo '❌ Pipeline failed! Consider cleaning up resources.'
            echo 'Check the logs above for detailed error information.'
            echo 'You may need to manually clean up Azure resources if Terraform apply succeeded.'
        }
    }
}