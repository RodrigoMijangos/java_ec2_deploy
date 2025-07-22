#!/bin/bash

echo "Iniciando aplicación..."
JAR_NAME=$(ls /opt/apps/backend/app*.jar | head -n 1)

if [ -f "/etc/systemd/system/myapp.service" ]; then
        sudo systemctl daemon-reload
        sudo systemctl restart myapp.service
        echo "Servicio 'myapp.service' reiniciado"

        sleep 5

        MAX_RETRIES=3
        WAIT_TIME_SEC=5
        RETRY_COUNT=0
        PROCESS_FOUND=0

        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                echo "Verificando proceso (Intento $((RETRY_COUNT + 1)) de $MAX_RETRIES)..."
                ps aux | grep "java -jar /opt/apps/backend/app*.jar" | echo | grep -v grep > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    echo "Proceso encontrado."
                    PROCESS_FOUND=1
                    break
                else
                    echo "Proceso no encontrado, esperando $WAIT_TIME_SEC segundos..."
                    sleep $WAIT_TIME_SEC
                    RETRY_COUNT=$((RETRY_COUNT + 1))
                fi
        done

        if [ $PROCESS_FOUND -eq 0 ]; then
                echo "ADVERTENCIA: El proceso Java no se encontró después de $MAX_RETRIES intentos."
                exit 1
        else
                exit 0
        fi

else
        echo "ERROR: El archivo de servicio '/etc/systemd/system/myapp.service' no existe."
        exit 1
fi