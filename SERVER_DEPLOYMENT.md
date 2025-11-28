# Server-Side Deployment Guide

This guide explains how to clone the repository on your server and deploy Tomcat using Ansible.

## Prerequisites on Server

1. **Ansible installed**
   ```bash
   # On RHEL/CentOS
   sudo yum install -y ansible
   
   # On Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y ansible
   
   # Or via pip
   pip3 install ansible
   ```

2. **Git installed**
   ```bash
   # On RHEL/CentOS
   sudo yum install -y git
   
   # On Ubuntu/Debian
   sudo apt-get install -y git
   ```

3. **SSH access** to target servers (if deploying to remote servers)
4. **Sudo privileges** on target servers

## Step 1: Clone Repository on Server

```bash
# Clone the repository
git clone https://github.com/vishruthreddy/TOMCAT.git
cd TOMCAT
```

## Step 2: Configure Inventory

Edit `inventory/hosts` with your target server details:

```ini
[tomcat_servers]
# For local deployment (deploying on the same server)
localhost ansible_connection=local

# OR for remote deployment
target-server ansible_host=192.168.1.100 ansible_user=admin

[tomcat_servers:vars]
tomcat_version=9.0.85
tomcat_service_account=tomcat
tomcat_home=/opt/tomcat
tomcat_port=8080
```

## Step 3: Test Connectivity

```bash
# Run pre-flight checks
./test-connectivity.sh

# Or manually test
ansible tomcat_servers -m ping
ansible tomcat_servers -m ping --become
```

## Step 4: Deploy Tomcat

### Option A: Automated Deployment

```bash
# Run complete test workflow (includes validation)
./run-tests.sh
```

### Option B: Manual Step-by-Step

```bash
# 1. Dry run first (see what would change)
ansible-playbook tomcat-deploy.yml --check

# 2. Full deployment
ansible-playbook tomcat-deploy.yml

# 3. Validate deployment
ansible-playbook playbooks/validate-deployment.yml
```

## Step 5: Verify Deployment

```bash
# Check service status
systemctl status tomcat

# Test HTTP endpoint
curl http://localhost:8080

# Test sample application
curl http://localhost:8080/sample-app

# Test health check
curl http://localhost:8080/sample-app/health
```

## Deployment Scenarios

### Scenario 1: Deploy on Same Server (Localhost)

```ini
[tomcat_servers]
localhost ansible_connection=local
```

Then run:
```bash
ansible-playbook tomcat-deploy.yml
```

### Scenario 2: Deploy to Remote Server

```ini
[tomcat_servers]
remote-server ansible_host=192.168.1.100 ansible_user=admin
```

Ensure SSH key is set up:
```bash
ssh-copy-id admin@192.168.1.100
```

Then run:
```bash
ansible-playbook tomcat-deploy.yml
```

### Scenario 3: Deploy to Multiple Servers

```ini
[tomcat_servers]
server1 ansible_host=192.168.1.10 ansible_user=admin
server2 ansible_host=192.168.1.11 ansible_user=admin
server3 ansible_host=192.168.1.12 ansible_user=admin
```

Then run:
```bash
ansible-playbook tomcat-deploy.yml
```

## Custom Configuration

### Custom Port

```bash
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"
```

### Custom Service Account and Home

```bash
ansible-playbook tomcat-deploy.yml \
  -e "tomcat_service_account=myapp" \
  -e "tomcat_home=/opt/myapp"
```

### Multiple Custom Variables

```bash
ansible-playbook tomcat-deploy.yml \
  -e "tomcat_port=9090" \
  -e "tomcat_service_account=myapp" \
  -e "tomcat_home=/opt/myapp" \
  -e "tomcat_shutdown_port=9005"
```

## Troubleshooting

### If Ansible is not installed

```bash
# Install Python first
sudo yum install -y python3 python3-pip
# OR
sudo apt-get install -y python3 python3-pip

# Then install Ansible
pip3 install ansible
```

### If SSH connection fails

```bash
# Test SSH manually
ssh user@target-server

# Use password authentication
ansible-playbook tomcat-deploy.yml --ask-pass --ask-become-pass
```

### If port is already in use

```bash
# Check what's using the port
sudo netstat -tlnp | grep 8080

# Use different port
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"
```

## Quick Reference

```bash
# Clone repository
git clone https://github.com/vishruthreddy/TOMCAT.git
cd TOMCAT

# Configure inventory
nano inventory/hosts

# Test connectivity
./test-connectivity.sh

# Deploy
ansible-playbook tomcat-deploy.yml

# Validate
ansible-playbook playbooks/validate-deployment.yml

# Manage service
ansible-playbook playbooks/service-management.yml -e "service_action=restart"
```

## Updating from GitHub

If you make changes and push to GitHub, update on server:

```bash
cd TOMCAT
git pull origin main
```

## Logs and Debugging

```bash
# Run with verbose output
ansible-playbook tomcat-deploy.yml -v
ansible-playbook tomcat-deploy.yml -vv
ansible-playbook tomcat-deploy.yml -vvv

# Check Tomcat logs
tail -f /opt/tomcat/logs/catalina.out

# Check systemd logs
journalctl -u tomcat -f
```

