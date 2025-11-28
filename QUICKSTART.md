# Quick Start Guide

## Prerequisites Check

```bash
# Check Ansible version
ansible --version

# Should be 2.9.0 or higher
```

## Step 1: Configure Inventory

Edit `inventory/hosts`:

```ini
[tomcat_servers]
my-server ansible_host=192.168.1.100 ansible_user=admin
```

## Step 2: Test Connectivity

```bash
ansible tomcat_servers -m ping
```

## Step 3: Run Deployment

```bash
# Full deployment
ansible-playbook tomcat-deploy.yml

# With custom port
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"

# With custom service account
ansible-playbook tomcat-deploy.yml \
  -e "tomcat_service_account=myapp" \
  -e "tomcat_home=/opt/myapp"
```

## Step 4: Verify Deployment

```bash
# Run validation
ansible-playbook playbooks/validate-deployment.yml

# Or manually check
curl http://<server-ip>:8080/sample-app
```

## Common Commands

```bash
# Start service
ansible-playbook playbooks/service-management.yml -e "service_action=start"

# Stop service
ansible-playbook playbooks/service-management.yml -e "service_action=stop"

# Restart service
ansible-playbook playbooks/service-management.yml -e "service_action=restart"

# Check status
ansible-playbook playbooks/service-management.yml -e "service_action=status"
```

## Troubleshooting

If you encounter issues:

1. **Connection failed**: Check SSH access and credentials
2. **Permission denied**: Ensure sudo access is configured
3. **Port in use**: Change port with `-e "tomcat_port=9090"`
4. **Java not found**: Install Java manually or check package names

For detailed information, see [README.md](README.md)

