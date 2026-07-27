#!/bin/bash
# Script de configuracion del servidor para la VM de Azure
set -e

REPO_URL="https://github.com/lex-bx/Tecnicas-de-despliegue-autom-tico.git"
APP_DIR="/var/www/app"
APP_USER="www-data"

echo "=== Actualizando sistema ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== Instalando Python y dependencias ==="
sudo apt-get install -y python3 python3-pip python3-venv nginx git

echo "=== Clonando repositorio ==="
sudo mkdir -p $APP_DIR
sudo chown $APP_USER:$APP_USER $APP_DIR
sudo -u $APP_USER git clone $REPO_URL $APP_DIR

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

    location /static/ {
        alias /var/www/app/static/;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "=== Configurando entorno virtual ==="
sudo -u $APP_USER python3 -m venv $APP_DIR/venv
sudo -u $APP_USER $APP_DIR/venv/bin/pip install --upgrade pip
sudo -u $APP_USER $APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt

echo "=== Configurando servicio systemd para la app ==="
sudo tee /etc/systemd/system/app.service << EOF
[Unit]
Description=Flask Application
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable app
sudo systemctl start app

echo "=== Configuracion completada ==="
echo "La aplicacion se actualizara automaticamente via GitHub Actions"
