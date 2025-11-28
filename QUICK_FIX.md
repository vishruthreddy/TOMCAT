# Quick Fix for Connectivity Issue

## Problem
You're getting: `✗ SSH connectivity failed`

## Solution: Configure Inventory for Local Deployment

Since you're running on the server itself, configure the inventory for local deployment.

### Step 1: Edit inventory/hosts

```bash
nano inventory/hosts
```

### Step 2: Add localhost configuration

Replace the content with:

```ini
[tomcat_servers]
localhost ansible_connection=local

[tomcat_servers:vars]
tomcat_version=9.0.85
tomcat_service_account=tomcat
tomcat_home=/opt/tomcat
tomcat_port=8080
tomcat_shutdown_port=8005
tomcat_ajp_port=8009
```

### Step 3: Test again

```bash
./test-connectivity.sh
```

Or test manually:

```bash
ansible tomcat_servers -m ping
```

## Alternative: Use Example File

```bash
# Copy example file
cp inventory/hosts.example inventory/hosts

# Edit if needed
nano inventory/hosts
```

## What's the difference?

- **Local deployment** (`ansible_connection=local`): Deploys on the same server where you run Ansible
- **Remote deployment**: Connects via SSH to deploy on a different server

Since you're on `root@mccd-centralizedqa`, use local deployment.

