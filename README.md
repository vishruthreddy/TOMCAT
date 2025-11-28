# Tomcat Deployment with Ansible

This Ansible playbook provides a comprehensive solution for deploying Apache Tomcat with all enterprise requirements including service account setup, custom port configuration, application deployment, and automated validation.

## Features

✅ **Service Account Setup**
- Creates dedicated service account with custom home folder
- Configures proper ownership and permissions

✅ **Multi-OS Support**
- RHEL/CentOS (yum)
- Ubuntu/Debian (apt)
- Windows (basic support)

✅ **Port Configuration**
- Configurable HTTP port (default: 8080)
- Configurable shutdown port (default: 8005)
- Configurable AJP port (default: 8009)

✅ **Permissions & Access**
- Read access for all users
- Write permissions for service account
- Proper directory structure ownership

✅ **Service Management**
- Systemd service configuration
- Auto-start on system boot
- Start/Stop/Restart functionality

✅ **Application Deployment**
- Sample application deployment
- Health check endpoint
- Custom context path support

✅ **Logging Configuration**
- Configurable log levels
- Access log support
- Centralized log directory

✅ **Validation & Testing**
- Comprehensive validation checks
- Service status verification
- Port accessibility testing
- Application accessibility testing

## Directory Structure

```
TOMCAT/
├── ansible.cfg                 # Ansible configuration
├── tomcat-deploy.yml          # Main deployment playbook
├── inventory/
│   └── hosts                  # Inventory file
├── group_vars/
│   ├── all/
│   │   └── main.yml          # Global variables
│   ├── redhat/
│   │   └── main.yml          # RHEL/CentOS variables
│   ├── debian/
│   │   └── main.yml          # Ubuntu/Debian variables
│   └── windows/
│       └── main.yml          # Windows variables
└── roles/
    ├── service-account/       # Service account creation
    ├── tomcat-install/        # Tomcat installation
    ├── permissions/           # Permission configuration
    ├── service-config/        # Service and port configuration
    ├── app-deploy/            # Application deployment
    └── validation/            # Validation and testing
```

## Prerequisites

1. **Ansible Installation**
   ```bash
   # On RHEL/CentOS
   sudo yum install ansible

   # On Ubuntu/Debian
   sudo apt-get install ansible

   # Or via pip
   pip install ansible
   ```

2. **Target Server Requirements**
   - Linux server (RHEL 7+, CentOS 7+, Ubuntu 18.04+, Debian 10+)
   - SSH access with sudo privileges
   - Internet connectivity for downloading Tomcat
   - At least 1GB free disk space

3. **Python Requirements**
   - Python 2.7+ or Python 3.5+ on target servers
   - Required Python modules: `urllib3`, `requests`

## Configuration

### 1. Inventory Setup

Edit `inventory/hosts` and add your target servers:

```ini
[tomcat_servers]
tomcat-server-1 ansible_host=192.168.1.10 ansible_user=admin
tomcat-server-2 ansible_host=192.168.1.11 ansible_user=admin

[tomcat_servers:vars]
tomcat_version=9.0.85
tomcat_service_account=tomcat
tomcat_home=/opt/tomcat
tomcat_port=8080
```

### 2. Variable Configuration

Edit `group_vars/all/main.yml` to customize:

```yaml
# Service Account
tomcat_service_account: "tomcat"
tomcat_home: "/opt/tomcat"

# Port Configuration
tomcat_port: 8080
tomcat_shutdown_port: 8005
tomcat_ajp_port: 8009

# Application
app_name: "sample-app"
app_context_path: "/sample-app"
```

### 3. SSH Key Setup

Ensure SSH key-based authentication is configured:

```bash
ssh-copy-id user@target-server
```

Or use password authentication (less secure):

```bash
ansible-playbook tomcat-deploy.yml --ask-pass --ask-become-pass
```

## Usage

### Full Deployment

Deploy Tomcat with all features:

```bash
ansible-playbook tomcat-deploy.yml
```

### Tagged Execution

Run specific components:

```bash
# Only service account setup
ansible-playbook tomcat-deploy.yml --tags service-account

# Only installation
ansible-playbook tomcat-deploy.yml --tags install

# Only configuration
ansible-playbook tomcat-deploy.yml --tags config

# Only application deployment
ansible-playbook tomcat-deploy.yml --tags deploy

# Only validation
ansible-playbook tomcat-deploy.yml --tags validation
```

### Custom Port Deployment

Override default port:

```bash
ansible-playbook tomcat-deploy.yml -e "tomcat_port=9090"
```

### Multiple Ports Override

```bash
ansible-playbook tomcat-deploy.yml \
  -e "tomcat_port=9090" \
  -e "tomcat_shutdown_port=9005" \
  -e "tomcat_ajp_port=9009"
```

### Custom Service Account and Home

```bash
ansible-playbook tomcat-deploy.yml \
  -e "tomcat_service_account=myapp" \
  -e "tomcat_home=/opt/myapp"
```

## Service Management

### Start Tomcat Service

```bash
ansible tomcat_servers -m systemd -a "name=tomcat.service state=started" --become
```

### Stop Tomcat Service

```bash
ansible tomcat_servers -m systemd -a "name=tomcat.service state=stopped" --become
```

### Restart Tomcat Service

```bash
ansible tomcat_servers -m systemd -a "name=tomcat.service state=restarted" --become
```

### Check Service Status

```bash
ansible tomcat_servers -m systemd -a "name=tomcat.service" --become
```

## Validation

The validation role automatically checks:

1. ✅ Service account exists with correct home directory
2. ✅ Service is running and enabled on boot
3. ✅ Process is running under service account
4. ✅ HTTP endpoint is accessible on custom port
5. ✅ Sample application is deployed and accessible
6. ✅ Health check endpoint is responding
7. ✅ Service start/stop/restart functionality works
8. ✅ File permissions are correctly set

### Manual Validation

```bash
# Check service status
systemctl status tomcat

# Check if running under service account
ps aux | grep catalina

# Test HTTP endpoint
curl http://localhost:8080

# Test sample application
curl http://localhost:8080/sample-app

# Test health check
curl http://localhost:8080/sample-app/health
```

## Accessing the Application

After deployment, access:

- **Tomcat Default Page**: `http://<server-ip>:<port>/`
- **Sample Application**: `http://<server-ip>:<port>/sample-app`
- **Health Check**: `http://<server-ip>:<port>/sample-app/health`

## Custom Application Deployment

To deploy your own application:

1. Place your WAR file in `roles/app-deploy/files/`
2. Update `group_vars/all/main.yml`:
   ```yaml
   app_name: "my-application"
   app_context_path: "/my-app"
   app_war_file: "my-application.war"
   ```
3. Modify `roles/app-deploy/tasks/main.yml` to copy your WAR file

## Troubleshooting

### Service Won't Start

1. Check logs:
   ```bash
   tail -f /opt/tomcat/logs/catalina.out
   ```

2. Check service status:
   ```bash
   systemctl status tomcat
   journalctl -u tomcat -n 50
   ```

3. Verify Java installation:
   ```bash
   java -version
   ```

### Port Already in Use

If the port is already in use:

1. Find the process:
   ```bash
   sudo netstat -tlnp | grep 8080
   ```

2. Change the port in `group_vars/all/main.yml` or use `-e` flag

### Permission Denied

Ensure the service account has proper permissions:

```bash
sudo chown -R tomcat:tomcat /opt/tomcat
```

### Application Not Accessible

1. Check if application is deployed:
   ```bash
   ls -la /opt/tomcat/webapps/
   ```

2. Check Tomcat logs:
   ```bash
   tail -f /opt/tomcat/logs/catalina.out
   ```

3. Verify context path in `server.xml` and `web.xml`

## Advanced Configuration

### JVM Tuning

Edit `roles/service-config/templates/setenv.sh.j2`:

```bash
export CATALINA_OPTS="-Xms1024m -Xmx2048m -XX:MetaspaceSize=256m"
```

### Logging Configuration

Edit `roles/service-config/templates/logging.properties.j2` to customize log levels and handlers.

### SSL/HTTPS Configuration

Add SSL connector configuration in `roles/service-config/templates/server.xml.j2`.

## OS-Specific Notes

### RHEL/CentOS

- Uses `yum` package manager
- Java package: `java-11-openjdk-devel`
- Systemd service: `/etc/systemd/system/tomcat.service`

### Ubuntu/Debian

- Uses `apt` package manager
- Java package: `openjdk-11-jdk`
- Systemd service: `/etc/systemd/system/tomcat.service`

### Windows

- Basic support included
- Requires manual configuration for Windows-specific paths
- Consider using Windows Subsystem for Linux (WSL) for better compatibility

## Security Considerations

1. **Firewall**: Ensure firewall rules allow access to configured ports
2. **Service Account**: Use dedicated service account (not root)
3. **Permissions**: Follow principle of least privilege
4. **Updates**: Keep Tomcat and Java updated
5. **Manager Access**: Disable or secure Tomcat Manager if not needed

## Support

For issues or questions:

1. Check Ansible output for error messages
2. Review Tomcat logs in `/opt/tomcat/logs/`
3. Verify all prerequisites are met
4. Check systemd service logs: `journalctl -u tomcat`

## License

This playbook is provided as-is for deployment automation purposes.

## Version History

- **v1.0**: Initial release with full feature set
  - Service account setup
  - Multi-OS support
  - Port configuration
  - Application deployment
  - Comprehensive validation

