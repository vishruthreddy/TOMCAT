#!/bin/bash
# Quick test script for server connection

echo "=========================================="
echo "Testing Connection to matilda-svc"
echo "=========================================="
echo ""

# Test basic connectivity
echo "1. Testing ping..."
ansible tomcat_servers -m ping

echo ""
echo "2. Testing with become (sudo)..."
ansible tomcat_servers -m ping --become

echo ""
echo "3. Checking OS information..."
ansible tomcat_servers -m setup -a "filter=ansible_os_family" --become

echo ""
echo "4. Checking if Java is installed..."
ansible tomcat_servers -m shell -a "java -version 2>&1 || echo 'Java not installed'" --become

echo ""
echo "5. Checking port 8080..."
ansible tomcat_servers -m shell -a "netstat -tlnp 2>/dev/null | grep :8080 || echo 'Port 8080 is free'" --become

echo ""
echo "=========================================="
echo "Connection test completed!"
echo "=========================================="

