#!/bin/bash
# Script de configuracion del servidor para la VM de Azure
set -e

echo "=== Actualizando sistema ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== Instalando Python y dependencias ==="
sudo apt-get install -y python3 python3-pip python3-venv nginx git

echo "=== Creando directorio de la aplicacion ==="
sudo mkdir -p /var/www/app
sudo chown -R $USER:$USER /var/www/app

echo "=== Configurando Nginx ==="
sudo tee /etc/nginx/sites-available/app << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /var/www/app/static;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "=== Configurando servicio systemd para la app ==="
sudo tee /etc/systemd/system/app.service << 'EOF'
[Unit]
Description=Flask Application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/app
Environment="PATH=/var/www/app/venv/bin"
ExecStart=/var/www/app/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== Creando entorno virtual ==="
python3 -m venv /var/www/app/venv

echo "=== Configuracion inicial completada ==="
echo "La aplicacion se desplegara via GitHub Actions"
