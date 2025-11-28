# Testing Guide for Tomcat Ansible Deployment

## Prerequisites Checklist

Before testing, ensure you have:

- [ ] Ansible installed (`ansible --version`)
- [ ] Target test server (Linux - RHEL/CentOS/Ubuntu/Debian)
- [ ] SSH access to target server
- [ ] Sudo privileges on target server
- [ ] Internet connectivity on target server (for downloading Tomcat)

## Step 1: Configure Test Inventory

Edit `inventory/hosts` with your test server:

```ini
[tomcat_servers]
test-server ansible_host=YOUR_SERVER_IP ansible_user=YOUR_USERNAME

[tomcat_servers:vars]
tomcat_version=9.0.85
tomcat_service_account=tomcat
tomcat_home=/opt/tomcat
tomcat_port=8080
```

## Step 2: Test Connectivity

```bash
# Test SSH connectivity
ansible tomcat_servers -m ping

# Test with sudo
ansible tomcat_servers -m ping --become
```

## Step 3: Run Pre-flight Checks

```bash
# Check if ports are available
ansible tomcat_servers -m shell -a "netstat -tlnp | grep 8080 || echo 'Port 8080 is free'"

# Check Java installation
ansible tomcat_servers -m shell -a "java -version || echo 'Java not installed'"

# Check disk space
ansible tomcat_servers -m shell -a "df -h /opt"
```

## Step 4: Run Deployment (Dry Run First)

```bash
# Dry run to see what would change
ansible-playbook tomcat-deploy.yml --check

# Dry run with verbose output
ansible-playbook tomcat-deploy.yml --check -v
```

## Step 5: Full Deployment

```bash
# Full deployment
ansible-playbook tomcat-deploy.yml

# With verbose output for debugging
ansible-playbook tomcat-deploy.yml -v

# With extra verbose output
ansible-playbook tomcat-deploy.yml -vvv
```

## Step 6: Validate Deployment

```bash
# Run validation playbook
ansible-playbook playbooks/validate-deployment.yml

# Manual validation
ansible tomcat_servers -m shell -a "systemctl status tomcat"
ansible tomcat_servers -m shell -a "curl -s http://localhost:8080 | head -20"
ansible tomcat_servers -m shell -a "curl -s http://localhost:8080/sample-app | head -20"
```

## Step 7: Test Service Management

```bash
# Test service stop
ansible-playbook playbooks/service-management.yml -e "service_action=stop"

# Test service start
ansible-playbook playbooks/service-management.yml -e "service_action=start"

# Test service restart
ansible-playbook playbooks/service-management.yml -e "service_action=restart"

# Check service status
ansible-playbook playbooks/service-management.yml -e "service_action=status"
```

## Step 8: Test Custom Ports

```bash
# Deploy with custom port
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"

# Validate custom port
ansible tomcat_servers -m shell -a "curl -s http://localhost:9090 | head -20"
```

## Troubleshooting

### Connection Issues
```bash
# Test SSH manually
ssh YOUR_USERNAME@YOUR_SERVER_IP

# Test with password
ansible-playbook tomcat-deploy.yml --ask-pass --ask-become-pass
```

### Permission Issues
```bash
# Check sudo access
ansible tomcat_servers -m shell -a "sudo whoami" --become

# Test with specific user
ansible tomcat_servers -m shell -a "whoami" -u YOUR_USERNAME
```

### Port Already in Use
```bash
# Find what's using the port
ansible tomcat_servers -m shell -a "sudo netstat -tlnp | grep 8080"

# Use different port
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"
```

### Java Not Found
```bash
# Check Java installation
ansible tomcat_servers -m shell -a "which java"

# Install Java manually if needed
ansible tomcat_servers -m yum -a "name=java-11-openjdk-devel state=present" --become
# OR for Debian/Ubuntu
ansible tomcat_servers -m apt -a "name=openjdk-11-jdk state=present" --become
```

## Test Scenarios

### Scenario 1: Fresh Installation
- Clean server with no Tomcat
- Expected: Full installation and configuration

### Scenario 2: Existing Installation
- Server with existing Tomcat
- Expected: Update configuration or handle gracefully

### Scenario 3: Custom Configuration
- Custom port, service account, home directory
- Expected: All custom values applied correctly

### Scenario 4: Multi-OS Testing
- Test on RHEL, Ubuntu, Debian separately
- Expected: OS-specific configurations work correctly

## Validation Checklist

After deployment, verify:

- [ ] Service account created with correct home directory
- [ ] Tomcat installed in correct location
- [ ] Service is running
- [ ] Service enabled on boot
- [ ] Process running under service account
- [ ] Port is accessible
- [ ] Sample application deployed
- [ ] Health check endpoint working
- [ ] Logs are being written
- [ ] Permissions are correct

## Cleanup (if needed)

```bash
# Stop and remove service
ansible tomcat_servers -m systemd -a "name=tomcat state=stopped enabled=no" --become
ansible tomcat_servers -m file -a "path=/etc/systemd/system/tomcat.service state=absent" --become
ansible tomcat_servers -m file -a "path=/opt/tomcat state=absent" --become
ansible tomcat_servers -m user -a "name=tomcat state=absent" --become
```

