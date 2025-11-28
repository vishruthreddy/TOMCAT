#!/bin/bash
# Test connectivity and prerequisites before deployment

echo "=========================================="
echo "Tomcat Deployment - Pre-flight Checks"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if inventory file exists
if [ ! -f "inventory/hosts" ]; then
    echo -e "${RED}✗ inventory/hosts file not found${NC}"
    exit 1
fi

echo -e "${YELLOW}1. Testing SSH connectivity...${NC}"
# Check if inventory has any hosts configured
HOST_COUNT=$(ansible-inventory --list 2>/dev/null | grep -c "tomcat_servers" || echo "0")
if [ "$HOST_COUNT" = "0" ]; then
    echo -e "${RED}✗ No hosts configured in inventory/hosts${NC}"
    echo ""
    echo "   Please configure inventory/hosts with one of these options:"
    echo ""
    echo "   Option 1: Local deployment (deploy on this server)"
    echo "   [tomcat_servers]"
    echo "   localhost ansible_connection=local"
    echo ""
    echo "   Option 2: Remote deployment"
    echo "   [tomcat_servers]"
    echo "   target-server ansible_host=IP_ADDRESS ansible_user=USERNAME"
    echo ""
    exit 1
fi

if ansible tomcat_servers -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SSH connectivity successful${NC}"
else
    echo -e "${YELLOW}⚠ SSH connectivity test failed, trying with local connection...${NC}"
    # Try with local connection
    if ansible tomcat_servers -m ping -c local > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Local connection successful${NC}"
    else
        echo -e "${RED}✗ Connectivity failed${NC}"
        echo "   Try: ansible tomcat_servers -m ping --ask-pass"
        echo "   Or configure localhost: localhost ansible_connection=local"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}2. Testing sudo access...${NC}"
if ansible tomcat_servers -m ping --become > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Sudo access successful${NC}"
else
    echo -e "${RED}✗ Sudo access failed${NC}"
    echo "   Run: ansible tomcat_servers -m ping --become --ask-become-pass"
    exit 1
fi

echo ""
echo -e "${YELLOW}3. Checking Java installation...${NC}"
JAVA_CHECK=$(ansible tomcat_servers -m shell -a "java -version 2>&1 | head -1" --become 2>/dev/null)
if echo "$JAVA_CHECK" | grep -q "openjdk\|java"; then
    echo -e "${GREEN}✓ Java is installed${NC}"
    echo "   $JAVA_CHECK"
else
    echo -e "${YELLOW}⚠ Java not found - will be installed during deployment${NC}"
fi

echo ""
echo -e "${YELLOW}4. Checking port availability...${NC}"
PORT_CHECK=$(ansible tomcat_servers -m shell -a "netstat -tlnp 2>/dev/null | grep :8080 || echo 'Port 8080 is free'" --become 2>/dev/null)
if echo "$PORT_CHECK" | grep -q "free"; then
    echo -e "${GREEN}✓ Port 8080 is available${NC}"
else
    echo -e "${YELLOW}⚠ Port 8080 may be in use${NC}"
    echo "   $PORT_CHECK"
fi

echo ""
echo -e "${YELLOW}5. Checking disk space...${NC}"
DISK_SPACE=$(ansible tomcat_servers -m shell -a "df -h /opt | tail -1 | awk '{print \$4}'" --become 2>/dev/null)
echo -e "${GREEN}✓ Available space in /opt: $DISK_SPACE${NC}"

echo ""
echo -e "${YELLOW}6. Checking OS family...${NC}"
OS_FAMILY=$(ansible tomcat_servers -m setup -a "filter=ansible_os_family" 2>/dev/null | grep "ansible_os_family" | head -1 | awk '{print $2}' | tr -d '"')
if [ ! -z "$OS_FAMILY" ]; then
    echo -e "${GREEN}✓ OS Family: $OS_FAMILY${NC}"
else
    echo -e "${YELLOW}⚠ Could not detect OS family${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Pre-flight checks completed!${NC}"
echo "=========================================="
echo ""
echo "Ready to deploy? Run:"
echo "  ansible-playbook tomcat-deploy.yml"
echo ""

