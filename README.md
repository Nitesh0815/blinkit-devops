# 🛒 Blinkit DevOps — CI/CD Pipeline with Terraform, Ansible, Jenkins & Docker

![CI/CD](https://img.shields.io/badge/CI%2FCD-Jenkins-blue?logo=jenkins)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![Config](https://img.shields.io/badge/Config-Ansible-EE0000?logo=ansible)
![Container](https://img.shields.io/badge/Container-Docker-2496ED?logo=docker)
![Cloud](https://img.shields.io/badge/Cloud-AWS%20EC2-FF9900?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)

A fully automated DevOps pipeline for a Blinkit-style grocery web application. This project provisions cloud infrastructure, configures the server, and deploys a containerized application — all without a single manual step after the initial trigger.

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Configure AWS Credentials](#2-configure-aws-credentials)
  - [3. Provision Infrastructure with Terraform](#3-provision-infrastructure-with-terraform)
  - [4. Configure Server with Ansible](#4-configure-server-with-ansible)
  - [5. Set Up Jenkins Pipeline](#5-set-up-jenkins-pipeline)
  - [6. Trigger the Pipeline](#6-trigger-the-pipeline)
- [Pipeline Stages](#pipeline-stages)
- [Jenkins Configuration](#jenkins-configuration)
- [Environment Variables](#environment-variables)
- [Accessing the Application](#accessing-the-application)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Architecture Overview

```
Developer
   │
   │  git push
   ▼
GitHub Repository
   │
   │  webhook trigger
   ▼
Jenkins (AWS EC2)
   │
   ├── Stage 1: Checkout code
   ├── Stage 2: Docker build (Nginx + static app)
   ├── Stage 3: Docker push → Docker Hub
   └── Stage 4: Deploy container on EC2 port 80
                   │
                   ▼
            End User (Browser)
            http://<EC2-IP>:80
```

**Infrastructure provisioning flow:**

```
Local Machine
   ├── Terraform  →  AWS EC2 instance + Security Group
   └── Ansible    →  EC2 configured (Java + Docker + Jenkins)
```

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **Terraform** | Provision AWS EC2 instance and security groups as code |
| **Ansible** | Automate server configuration — Java, Docker, Jenkins |
| **Jenkins** | CI/CD server — watches GitHub and runs the pipeline |
| **Docker** | Containerize the app using Nginx as the web server |
| **Docker Hub** | Store and version Docker images |
| **AWS EC2** | Host the Jenkins server and the running application |
| **GitHub** | Source code repository with webhook integration |

---

## Project Structure

```
blinkit-devops/
├── terraform/
│   ├── main.tf               # EC2 instance + security group
│   ├── variables.tf          # Region, AMI ID, instance type
│   └── outputs.tf            # Prints EC2 public IP after apply
│
├── ansible/
│   ├── inventory.ini         # EC2 host + SSH key config
│   └── playbook.yml          # Installs Java, Docker, Jenkins
│
├── app/                      # Blinkit frontend source code
│   ├── index.html
│   ├── css/
│   ├── js/
│   ├── images/
│   └── Dockerfile            # Nginx:alpine serving static files
│
├── Jenkinsfile               # 5-stage CI/CD pipeline definition
├── .gitignore                # Excludes .pem, .tfstate, .terraform/
└── README.md
```

---

## Prerequisites

Ensure the following are installed on your **local machine**:

| Tool | Install |
|---|---|
| AWS CLI v2 | `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install` |
| Terraform | `sudo apt install -y terraform` |
| Ansible | `sudo apt install -y ansible` |
| Git | `sudo apt install -y git` |

You also need:
- An **AWS account** with IAM user credentials (Access Key + Secret Key)
- A **Docker Hub account** at [hub.docker.com](https://hub.docker.com)
- An **AWS EC2 Key Pair** named `blinkit-key` (`.pem` file)

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Nitesh0815/blinkit-devops.git
cd blinkit-devops
```

### 2. Configure AWS Credentials

```bash
aws configure
# AWS Access Key ID:     <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name:   ap-south-1
# Default output format: json
```

Verify the connection:
```bash
aws sts get-caller-identity
```

### 3. Provision Infrastructure with Terraform

```bash
cd terraform

terraform init       # Download AWS provider
terraform plan       # Preview what will be created
terraform apply      # Type 'yes' to confirm
```

After apply completes, note the output:
```
ec2_public_ip = "X.X.X.X"
```

### 4. Configure Server with Ansible

Update `ansible/inventory.ini` with the EC2 IP from the previous step:

```ini
[jenkins_server]
X.X.X.X ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/blinkit-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

Run the playbook — this installs everything on EC2 automatically:

```bash
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml
```

At the end of the playbook run, the Jenkins URL and initial admin password are printed in the terminal output.

### 5. Set Up Jenkins Pipeline

1. Open `http://<EC2-IP>:8080` in your browser
2. Enter the initial admin password from the Ansible output
3. Install suggested plugins
4. Go to **Manage Jenkins → Credentials → Global → Add Credentials**:
   - Kind: `Username with password`
   - Username: your Docker Hub username
   - Password: your Docker Hub password
   - ID: `dockerhub-credentials`
5. Install plugins: **Docker Pipeline**, **GitHub Integration**
6. Create a new **Pipeline** job:
   - Build Trigger: `GitHub hook trigger for GITScm polling`
   - Pipeline: `Pipeline script from SCM` → Git → your repo URL → branch `*/main`
   - Script Path: `Jenkinsfile`

### 6. Trigger the Pipeline

Add the webhook in your GitHub repository:
- **Settings → Webhooks → Add webhook**
- Payload URL: `http://<EC2-IP>:8080/github-webhook/`
- Content type: `application/json`
- Event: Just the push event

Now every `git push` to `main` automatically triggers the full pipeline.

---

## Pipeline Stages

```
Checkout → Docker Build → Docker Push → Deploy → Verify
```

| Stage | Description |
|---|---|
| **Checkout** | Pulls latest code from the GitHub repository |
| **Docker Build** | Builds the Nginx container image from `app/Dockerfile` |
| **Docker Push** | Tags and pushes the image to Docker Hub |
| **Deploy** | Stops the old container, pulls the new image, runs it on port 80 |
| **Verify** | Confirms the container is running and prints the live URL |

---

## Jenkins Configuration

The pipeline is defined in `Jenkinsfile` at the root of the repository. Key environment variables at the top of the file:

```groovy
environment {
    DOCKER_IMAGE   = "YOUR_DOCKERHUB_USERNAME/blinkit-app"
    DOCKER_TAG     = "latest"
    CONTAINER_NAME = "blinkit-container"
    APP_PORT       = "80"
}
```

Update `YOUR_DOCKERHUB_USERNAME` with your actual Docker Hub username before running the pipeline.

---

## Environment Variables

| Variable | Description | Where to set |
|---|---|---|
| `DOCKER_IMAGE` | Docker Hub image name | `Jenkinsfile` |
| `DOCKER_TAG` | Image tag (default: `latest`) | `Jenkinsfile` |
| `CONTAINER_NAME` | Running container name | `Jenkinsfile` |
| `APP_PORT` | Host port for the app | `Jenkinsfile` |
| `dockerhub-credentials` | Docker Hub login | Jenkins Credentials store |

---

## Accessing the Application

Once the pipeline completes successfully:

```
http://<EC2-PUBLIC-IP>:80
```

Confirm the container is running on EC2:

```bash
ssh -i ~/.ssh/blinkit-key.pem ubuntu@<EC2-IP>
docker ps
```

---

## Cleanup

To destroy all AWS resources and avoid charges:

```bash
cd terraform
terraform destroy   # Type 'yes' to confirm
```

This deletes the EC2 instance and security group completely.

---

## Troubleshooting

| Problem | Likely Cause | Fix |
|---|---|---|
| `ansible-playbook` fails on Jenkins repo | Jenkins GPG key expired (March 2026) | Playbook uses WAR method — no apt key needed |
| Jenkins not starting | Not enough memory on instance | Use `t2.medium` or add `-Xmx512m` to ExecStart |
| `docker: permission denied` | Jenkins not in docker group | Re-run Ansible playbook or run `sudo usermod -aG docker jenkins` then restart |
| Pipeline fails on Docker push | Wrong credentials ID | Ensure credential ID is exactly `dockerhub-credentials` |
| App not accessible on port 80 | Security group missing rule | Add inbound rule for port 80 in AWS Console or Terraform |
| Webhook not triggering Jenkins | Port 8080 not open | Add inbound rule for port 8080 in security group |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## Author

**Nitesh Kumar**
- GitHub: [@Nitesh0815](https://github.com/Nitesh0815)

---

## License

This project is licensed under the MIT License.

---

> Built as a hands-on DevOps project to learn real-world CI/CD practices with Terraform, Ansible, Jenkins, Docker, and AWS.
