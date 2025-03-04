#!/bin/bash

# Get user input
read -p "Enter the domain name (e.g., example.com): " DOMAIN

# Get VM's public IP
VM_IP=$(curl -s ifconfig.me)

# Get domain's current IP
DOMAIN_IP=$(nslookup $DOMAIN | awk '/^Address: / { print $2 }' | tail -n1)

# Compare and show result
echo "🔍 Checking if $DOMAIN points to the VM IP ($VM_IP)..."

if [[ "$DOMAIN_IP" == "$VM_IP" ]]; then
    echo "✅ Yes, the domain $DOMAIN is correctly routed to this VM ($VM_IP)."
else
    echo "❌ No, $DOMAIN is currently routed to $DOMAIN_IP instead of $VM_IP."
fi