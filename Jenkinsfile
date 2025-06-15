pipeline {
    agent any

    environment {
        AZURE_SUBSCRIPTION_ID = credentials('3e47ba0e-8067-42b7-bda9-33f85d9d39a5 ')
        AZURE_CLIENT_ID = credentials('1d1775eb-7ca9-4356-a242-aee191fc4d20')
        AZURE_CLIENT_SECRET = credentials('71384082-b5c5-4ae8-acd5-af0822a95dc7')
        AZURE_TENANT_ID = credentials('78a31f2f-a764-4a56-a3b9-832c487e790b')
        SSH_KEY = credentials('d1775eb-7ca9-4356-a242-aee191fc4d20')
        TF_VAR_ssh_public_key = credentials('ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCm+3GpYp1p0ac+P+zpozWewT8ijx9XJKHDDypfwMT2vOs3hej2TMctp/T8c+NFqcvbtPc0o5zI2QlyJAxuLq/oq7/VL0QNTJB1OMQDfXVBootSpk20strGItOs26hsZh9eHrguFoiUcSYP0LZljMaPhLn14yrVCWjKnVokFdXcVJ2CvMATC6KoypAsV1bXJChaggP1KzLr4y6+z0tWv797YUqO8RTeDvbGiZVy63AOhpQ+Wi5xJ+q4SxJZq2b8yd/Qbi8yv5yOaICJgUhVOT6MQPIykGUjUJjoqFgz+7jRlDhN6xZmTXrCiVPEZ+wFi5E4HS59nhEoy1xuh1RiP8Ia9qWezRpAxuWuJXDAWRceGaBeA5ewJADfCXCBlPyWgj5r7Ou4/KM34+VhtkgUfXjf4NDMStu59M5tnau9T7MHmvmY7B2tkTTqp5laP6oUCPjG0/4nLTsK+yZZ4SoKnlTzLaKbQVr+IBT0nVuFdN1pFcNBZ8x/4HXJaWfeVHa2o0hWoW1EDUEwrWbxw8+jpHx1PjcareCFWzG32Z9ZvDLyUdDABgO44pW0Dy2O8wSLDuKHU32gzFlN1tryAivSfv8x8U7Z/gDFvT82b+6r+wzHN/FozfizpU031UeVIEDOIovTAItMP6B+cVnPiVA2bFhuRb6ogVmDS9AVrj5Qhuwumw== syed@SandboxHost-638855889453690753')
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