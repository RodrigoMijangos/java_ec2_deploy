#!/bin/bash

SERVICE_NAME="myapp.service"
APP_DIR="/opt/apps/backend/"

echo ">>> [PRE-DEPLOY] INICIANDO..."

if systemctl is-active --quiet $SERVICE_NAME; then
    echo "Deteniendo servicio $SERVICE_NAME..."
    sudo systemctl stop $SERVICE_NAME
else
    echo "El servicio ya se encuentra detenido"
fi

echo "Eliminando jars antiguos en $APP_DIR..."

find "$APP_DIR" -name "app*.jar" -type f -delete || true

echo ">>> [PRE-DEPLOY] COMPLETADO"