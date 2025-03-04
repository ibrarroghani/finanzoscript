#!/bin/bash

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || { echo "❌ Error: $1 is not installed. Install it and rerun the script."; exit 1; }
}

# Ensure required commands exist
check_command "curl"
check_command "nslookup"
check_command "nginx"
check_command "certbot"

# Get user input for the domain
read -p "Enter the domain name (e.g., example.com): " DOMAIN

# Get VM's public IP
VM_IP=$(curl -s ifconfig.me)

# Get domain's current IP
DOMAIN_IP=$(nslookup "$DOMAIN" | awk '/^Address: / { print $2 }' | tail -n1)

# Check if the domain is routed correctly
echo "🔍 Checking if $DOMAIN points to the VM IP ($VM_IP)..."

if [[ "$DOMAIN_IP" == "$VM_IP" ]]; then
    echo "✅ Yes, the domain $DOMAIN is correctly routed to this VM ($VM_IP)."
else
    echo "❌ No, $DOMAIN is currently routed to $DOMAIN_IP instead of $VM_IP."
    exit 1
fi

# Ask user if they want to configure Nginx and SSL
read -p "Do you want to configure Nginx reverse proxy and SSL? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "❌ Exiting without configuring Nginx and SSL."
    exit 0
fi

# Get user input for localhost port
read -p "Enter the localhost port for proxy (e.g., 3000): " LOCAL_PORT

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "📥 Installing Nginx..."
    sudo apt update && sudo apt install -y nginx
fi

# Create an Nginx configuration file
echo "⚙️ Setting up Nginx reverse proxy for $DOMAIN..."
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$LOCAL_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the Nginx site
sudo ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
echo "✅ Nginx configured successfully!"

# Install Certbot if not installed
if ! command -v certbot &> /dev/null; then
    echo "📥 Installing Certbot..."
    sudo apt install -y certbot python3-certbot-nginx
fi

# Obtain SSL certificate and enable HTTPS
echo "🔐 Requesting SSL certificate for $DOMAIN..."
sudo certbot --nginx -d "$DOMAIN" --agree-tos --email admin@$DOMAIN --redirect --non-interactive

# Restart Nginx to apply changes
sudo systemctl restart nginx
echo "✅ SSL setup completed for $DOMAIN!"
