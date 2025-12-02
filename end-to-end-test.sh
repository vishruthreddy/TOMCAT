#!/bin/bash
# End-to-End Test Script for Tomcat Deployment
# Run this on your server to test the complete workflow

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print section header
print_header() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

# Function to print test result
print_test() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ $2${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to run command and check result
run_test() {
    local test_name="$1"
    shift
    echo -e "${YELLOW}Testing: $test_name${NC}"
    if "$@" > /tmp/test_output.log 2>&1; then
        print_test 0 "$test_name"
        return 0
    else
        print_test 1 "$test_name"
        echo -e "${RED}Error output:${NC}"
        cat /tmp/test_output.log | tail -10
        return 1
    fi
}

# Start of tests
clear
print_header "Tomcat Deployment - End-to-End Test"
echo -e "${CYAN}This script will test the complete Tomcat deployment workflow${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "tomcat-deploy.yml" ]; then
    echo -e "${RED}Error: tomcat-deploy.yml not found${NC}"
    echo "Please run this script from the TOMCAT directory"
    exit 1
fi

# Step 1: Pre-flight Checks
print_header "Step 1: Pre-flight Checks"

# Check Ansible installation
run_test "Ansible is installed" ansible --version

# Check inventory file
if [ -f "inventory/hosts" ]; then
    print_test 0 "Inventory file exists"
    HOST_COUNT=$(grep -c "^[a-zA-Z]" inventory/hosts || echo "0")
    if [ "$HOST_COUNT" -gt 0 ]; then
        print_test 0 "Inventory has hosts configured"
    else
        print_test 1 "Inventory has no hosts configured"
    fi
else
    print_test 1 "Inventory file not found"
fi

# Test connectivity
print_header "Step 2: Connectivity Tests"

run_test "SSH connectivity to servers" ansible tomcat_servers -m ping
run_test "Sudo access on servers" ansible tomcat_servers -m ping --become

# Check OS detection
echo -e "${YELLOW}Detecting OS on target servers...${NC}"
ansible tomcat_servers -m setup -a "filter=ansible_os_family" --become 2>/dev/null | grep "ansible_os_family" | head -2
print_test 0 "OS detection working"

# Step 3: Prerequisites Check
print_header "Step 3: Prerequisites Check"

# Check Java
echo -e "${YELLOW}Checking Java installation...${NC}"
JAVA_CHECK=$(ansible tomcat_servers -m shell -a "java -version 2>&1 | head -1 || echo 'NOT_INSTALLED'" --become 2>/dev/null)
if echo "$JAVA_CHECK" | grep -q "openjdk\|java"; then
    print_test 0 "Java is installed"
    echo "  $JAVA_CHECK"
else
    print_test 1 "Java not installed (will be installed during deployment)"
fi

# Check port availability
echo -e "${YELLOW}Checking port 8080 availability...${NC}"
PORT_CHECK=$(ansible tomcat_servers -m shell -a "netstat -tlnp 2>/dev/null | grep :8080 || echo 'PORT_FREE'" --become 2>/dev/null)
if echo "$PORT_CHECK" | grep -q "PORT_FREE"; then
    print_test 0 "Port 8080 is available"
else
    print_test 1 "Port 8080 may be in use"
    echo "  $PORT_CHECK"
fi

# Check disk space
echo -e "${YELLOW}Checking disk space...${NC}"
DISK_SPACE=$(ansible tomcat_servers -m shell -a "df -h /opt | tail -1" --become 2>/dev/null)
print_test 0 "Disk space check"
echo "  $DISK_SPACE"

# Step 4: Dry Run
print_header "Step 4: Dry Run (Check Mode)"

echo -e "${YELLOW}Running playbook in check mode (no changes will be made)...${NC}"
echo "This may take a few minutes..."
if ansible-playbook tomcat-deploy.yml --check > /tmp/dryrun.log 2>&1; then
    print_test 0 "Dry run completed successfully"
    echo -e "${GREEN}No errors found in dry run${NC}"
else
    print_test 1 "Dry run failed"
    echo -e "${RED}Errors found:${NC}"
    grep -i "error\|failed\|fatal" /tmp/dryrun.log | head -10 || cat /tmp/dryrun.log | tail -20
    echo ""
    read -p "Continue with actual deployment anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 5: Full Deployment
print_header "Step 5: Full Deployment"

echo -e "${YELLOW}Starting full deployment...${NC}"
echo "This will install and configure Tomcat on all servers"
echo "This may take 5-10 minutes..."
echo ""

if ansible-playbook tomcat-deploy.yml -v; then
    print_test 0 "Deployment completed successfully"
else
    print_test 1 "Deployment failed"
    echo -e "${RED}Check the error messages above${NC}"
    exit 1
fi

# Step 6: Validation
print_header "Step 6: Validation Tests"

echo -e "${YELLOW}Running validation playbook...${NC}"
if ansible-playbook playbooks/validate-deployment.yml; then
    print_test 0 "Validation passed"
else
    print_test 1 "Validation failed"
fi

# Step 7: Service Status Check
print_header "Step 7: Service Status Verification"

echo -e "${YELLOW}Checking service status on all servers...${NC}"
ansible tomcat_servers -m shell -a "systemctl status tomcat --no-pager" --become 2>/dev/null | grep -E "Active:|Loaded:" || true
print_test 0 "Service status check"

# Step 8: HTTP Endpoint Tests
print_header "Step 8: HTTP Endpoint Tests"

echo -e "${YELLOW}Testing HTTP endpoints...${NC}"

# Test main Tomcat page
HTTP_TEST=$(ansible tomcat_servers -m uri -a "url=http://localhost:8080 method=GET status_code=200,404" --become 2>/dev/null)
if echo "$HTTP_TEST" | grep -q "status_code.*200\|status_code.*404"; then
    print_test 0 "Tomcat HTTP endpoint accessible"
else
    print_test 1 "Tomcat HTTP endpoint not accessible"
fi

# Test sample application
APP_TEST=$(ansible tomcat_servers -m uri -a "url=http://localhost:8080/sample-app method=GET status_code=200" --become 2>/dev/null)
if echo "$APP_TEST" | grep -q "status_code.*200"; then
    print_test 0 "Sample application accessible"
else
    print_test 1 "Sample application not accessible"
fi

# Test health check
HEALTH_TEST=$(ansible tomcat_servers -m uri -a "url=http://localhost:8080/sample-app/health method=GET status_code=200" --become 2>/dev/null)
if echo "$HEALTH_TEST" | grep -q "status_code.*200"; then
    print_test 0 "Health check endpoint working"
else
    print_test 1 "Health check endpoint not working"
fi

# Step 9: Service Management Tests
print_header "Step 9: Service Management Tests"

echo -e "${YELLOW}Testing service restart...${NC}"
if ansible-playbook playbooks/service-management.yml -e "service_action=restart" > /dev/null 2>&1; then
    print_test 0 "Service restart successful"
    
    # Wait for service to be ready
    echo "Waiting for service to be ready..."
    sleep 10
    
    # Test if service is responding
    HTTP_AFTER_RESTART=$(ansible tomcat_servers -m uri -a "url=http://localhost:8080 method=GET status_code=200,404" --become 2>/dev/null)
    if echo "$HTTP_AFTER_RESTART" | grep -q "status_code.*200\|status_code.*404"; then
        print_test 0 "Service responding after restart"
    else
        print_test 1 "Service not responding after restart"
    fi
else
    print_test 1 "Service restart failed"
fi

# Step 10: Final Verification
print_header "Step 10: Final Verification"

echo -e "${YELLOW}Running final checks...${NC}"

# Check if service account exists
SERVICE_ACCOUNT_CHECK=$(ansible tomcat_servers -m shell -a "id tomcat 2>/dev/null || echo 'NOT_FOUND'" --become 2>/dev/null)
if echo "$SERVICE_ACCOUNT_CHECK" | grep -q "uid"; then
    print_test 0 "Service account 'tomcat' exists"
else
    print_test 1 "Service account 'tomcat' not found"
fi

# Check if Tomcat is running under service account
PROCESS_CHECK=$(ansible tomcat_servers -m shell -a "ps aux | grep '[c]atalina' | awk '{print \$1}'" --become 2>/dev/null)
if echo "$PROCESS_CHECK" | grep -q "tomcat"; then
    print_test 0 "Tomcat running under service account"
else
    print_test 1 "Tomcat not running under service account"
fi

# Check if service is enabled on boot
ENABLED_CHECK=$(ansible tomcat_servers -m shell -a "systemctl is-enabled tomcat 2>/dev/null || echo 'NOT_ENABLED'" --become 2>/dev/null)
if echo "$ENABLED_CHECK" | grep -q "enabled"; then
    print_test 0 "Service enabled on boot"
else
    print_test 1 "Service not enabled on boot"
fi

# Summary
print_header "Test Summary"

echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo "🎉 ALL TESTS PASSED!"
    echo "==========================================${NC}"
    echo ""
    echo "Tomcat deployment is successful!"
    echo ""
    echo "Access your Tomcat instances:"
    ansible tomcat_servers -m setup -a "filter=ansible_default_ipv4" --become 2>/dev/null | grep "ansible_default_ipv4" | head -2
    echo ""
    echo "Tomcat URLs:"
    echo "  - http://<server-ip>:8080"
    echo "  - http://<server-ip>:8080/sample-app"
    echo "  - http://<server-ip>:8080/sample-app/health"
    echo ""
    exit 0
else
    echo -e "${YELLOW}=========================================="
    echo "⚠ Some tests failed"
    echo "==========================================${NC}"
    echo ""
    echo "Please review the errors above and fix them."
    echo ""
    exit 1
fi

