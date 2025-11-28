#!/bin/bash
# Complete test workflow for Tomcat deployment

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "Tomcat Deployment - Complete Test Workflow"
echo "==========================================${NC}"
echo ""

# Step 1: Pre-flight checks
echo -e "${YELLOW}Step 1: Running pre-flight checks...${NC}"
if ./test-connectivity.sh; then
    echo -e "${GREEN}✓ Pre-flight checks passed${NC}"
else
    echo -e "${RED}✗ Pre-flight checks failed${NC}"
    exit 1
fi

echo ""
read -p "Continue with deployment? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 2: Dry run
echo ""
echo -e "${YELLOW}Step 2: Running dry-run (check mode)...${NC}"
if ansible-playbook tomcat-deploy.yml --check; then
    echo -e "${GREEN}✓ Dry-run completed${NC}"
else
    echo -e "${RED}✗ Dry-run failed${NC}"
    exit 1
fi

echo ""
read -p "Continue with actual deployment? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 3: Full deployment
echo ""
echo -e "${YELLOW}Step 3: Running full deployment...${NC}"
if ansible-playbook tomcat-deploy.yml; then
    echo -e "${GREEN}✓ Deployment completed${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

# Step 4: Validation
echo ""
echo -e "${YELLOW}Step 4: Running validation...${NC}"
if ansible-playbook playbooks/validate-deployment.yml; then
    echo -e "${GREEN}✓ Validation passed${NC}"
else
    echo -e "${RED}✗ Validation failed${NC}"
    exit 1
fi

# Step 5: Service management tests
echo ""
echo -e "${YELLOW}Step 5: Testing service management...${NC}"
echo "Testing service restart..."
if ansible-playbook playbooks/service-management.yml -e "service_action=restart" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Service restart successful${NC}"
else
    echo -e "${RED}✗ Service restart failed${NC}"
fi

# Step 6: Manual verification
echo ""
echo -e "${YELLOW}Step 6: Manual verification commands...${NC}"
echo "Run these commands to verify:"
echo ""
echo "  # Check service status"
echo "  ansible tomcat_servers -m shell -a 'systemctl status tomcat' --become"
echo ""
echo "  # Test HTTP endpoint"
echo "  ansible tomcat_servers -m shell -a 'curl -s http://localhost:8080 | head -20'"
echo ""
echo "  # Test sample application"
echo "  ansible tomcat_servers -m shell -a 'curl -s http://localhost:8080/sample-app | head -20'"
echo ""
echo "  # Test health check"
echo "  ansible tomcat_servers -m shell -a 'curl -s http://localhost:8080/sample-app/health'"
echo ""

echo -e "${GREEN}=========================================="
echo "Test workflow completed!"
echo "==========================================${NC}"

