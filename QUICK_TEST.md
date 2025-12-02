# Quick Test Guide - Run on Your Server

## Prerequisites

Make sure you're in the TOMCAT directory:
```bash
cd ~/TOMCAT
# or wherever you cloned the repository
```

## Option 1: Complete End-to-End Test (Recommended)

Run the comprehensive test script:

```bash
./end-to-end-test.sh
```

This will:
1. ✅ Check prerequisites
2. ✅ Test connectivity
3. ✅ Run dry-run
4. ✅ Deploy Tomcat
5. ✅ Validate deployment
6. ✅ Test all endpoints
7. ✅ Test service management
8. ✅ Provide summary

## Option 2: Step-by-Step Manual Testing

### Step 1: Test Connectivity
```bash
./test-connectivity.sh
```

### Step 2: Dry Run (No Changes)
```bash
ansible-playbook tomcat-deploy.yml --check
```

### Step 3: Full Deployment
```bash
ansible-playbook tomcat-deploy.yml
```

### Step 4: Validate
```bash
ansible-playbook playbooks/validate-deployment.yml
```

### Step 5: Test Service Management
```bash
ansible-playbook playbooks/service-management.yml -e "service_action=restart"
```

### Step 6: Manual Verification
```bash
# Check service status
ansible tomcat_servers -m shell -a "systemctl status tomcat" --become

# Test HTTP endpoint
ansible tomcat_servers -m shell -a "curl -s http://localhost:8080 | head -20" --become

# Test sample app
ansible tomcat_servers -m shell -a "curl -s http://localhost:8080/sample-app | head -20" --become

# Test health check
ansible tomcat_servers -m shell -a "curl -s http://localhost:8080/sample-app/health" --become
```

## Option 3: Test Individual Components

### Test Specific Server
```bash
# Test only Ubuntu server
ansible-playbook tomcat-deploy.yml --limit matilda-svc-ubuntu

# Test only RHEL server
ansible-playbook tomcat-deploy.yml --limit matilda-svc-rhel
```

### Test with Verbose Output
```bash
ansible-playbook tomcat-deploy.yml -v    # Verbose
ansible-playbook tomcat-deploy.yml -vv   # More verbose
ansible-playbook tomcat-deploy.yml -vvv  # Debug mode
```

## Troubleshooting

### If connectivity fails:
```bash
# Test SSH manually
ssh root@172.24.8.218
ssh root@172.24.7.81

# Test with Ansible
ansible tomcat_servers -m ping --ask-pass
```

### If deployment fails:
```bash
# Check logs
tail -f /opt/tomcat/logs/catalina.out

# Check service status
systemctl status tomcat

# Check systemd logs
journalctl -u tomcat -n 50
```

### If port is in use:
```bash
# Find what's using the port
ansible tomcat_servers -m shell -a "sudo netstat -tlnp | grep 8080" --become

# Use different port
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"
```

## Expected Results

After successful deployment:

✅ Service account `tomcat` created
✅ Tomcat installed in `/opt/tomcat`
✅ Service running and enabled on boot
✅ Port 8080 accessible
✅ Sample application deployed at `/sample-app`
✅ Health check working at `/sample-app/health`
✅ Service management (start/stop/restart) working

## Quick Commands Reference

```bash
# Test connectivity
./test-connectivity.sh

# Full end-to-end test
./end-to-end-test.sh

# Deploy
ansible-playbook tomcat-deploy.yml

# Validate
ansible-playbook playbooks/validate-deployment.yml

# Restart service
ansible-playbook playbooks/service-management.yml -e "service_action=restart"

# Check status
ansible tomcat_servers -m shell -a "systemctl status tomcat" --become
```

