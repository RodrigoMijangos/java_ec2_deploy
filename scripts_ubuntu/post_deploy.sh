#!/bin/bash

SERVICE_NAME="myapp.service"

echo ">>> [POST-DEPLOY] INICIANDO"

sudo systemctl daemon-reload
echo "Reiniciando $SERVICE_NAME..."
sudo systemctl start $SERVICE_NAME

echo "VERIFICANDO ESTADO"

if systemctl is-active --quiet $SERVICE_NAME; then
        echo "SUCCESS: EL SERVICIO ESTÁ EN LINEA"
        exit 0
else
        echo "ERROR: El servicio falló al iniciar"
        sudo journalctl -u $SERVICE_NAME -n 10 --no-pager
        exit 1
fi