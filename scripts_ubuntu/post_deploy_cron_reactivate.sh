#!/bin/bash

echo "Iniciando la aplicación..."
JAR_NAME=$(ls /opt/apps/backend/app*.jar | head -n 1)

MONITOR_SCRIPT="/opt/apps/backend/scripts/monitor_app_status.sh"
CRON_ENTRY_FILE="/etc/cron.d/myapp_monitor_cron"
CRON_DISABLED_FLAG="/var/log/app_monitor/cron_disabled.flag"
MONITOR_LOG="/var/log/app_monitor/monitor_log.txt"
CRON_SCHEDULE="*/1 * * * *" # Debe coincidir con el del script de monitoreo

if [ -f "/etc/systemd/system/myapp.service" ]; then
    sudo systemctl daemon-reload
    sudo systemctl restart myapp.service && RESTART_STATUS=$? || RESTART_STATUS=$?
    
    echo "Servicio 'myapp.service' reiniciado."

    # Esperar un momento para que la app se levante y el health check funcione
    sleep 10 # Aumenta si tu app tarda más en iniciar

    # --- Lógica de Habilitación/Reanudación del Cron de Monitoreo ---
    # Asegúrate de que el directorio de logs exista y el usuario pueda escribir
    sudo mkdir -p "$(dirname "$MONITOR_LOG")"
    sudo chown "$USER":"$(id -gn)" "$(dirname "$MONITOR_LOG")"

    if [ -f "$MONITOR_SCRIPT" ]; then
        echo "Habilitando/Reanudando el cron job de monitoreo..."
        # El script 'monitor_app_status.sh' tiene una función para habilitar el cron.
        # La forma más robusta es que el post-deploy lo genere directamente.
        
        # Eliminar el flag de deshabilitado si existe
        sudo rm -f "$CRON_DISABLED_FLAG"

        # Crear o sobrescribir el archivo de cron en /etc/cron.d/
        # Esto asegura que el cron job se ejecute con el usuario 'root'
        echo "$CRON_SCHEDULE root $MONITOR_SCRIPT >> $MONITOR_LOG 2>&1" | sudo tee "$CRON_ENTRY_FILE" > /dev/null
        sudo chmod 644 "$CRON_ENTRY_FILE" # Permisos recomendados

        echo "Cron job de monitoreo debería estar activo ahora."
    else
        echo "ADVERTENCIA: Script de monitoreo ($MONITOR_SCRIPT) no encontrado. No se pudo habilitar el cron."
    fi

    # ... (Tu lógica de verificación final de ps aux | grep si aún la necesitas) ...
    # Asegurarse de que el script post-deploy salga con 0 si el restart fue exitoso.
    exit $RESTART_STATUS 
else
    echo "ERROR: El archivo de servicio '/etc/systemd/system/myapp.service' no existe."
    echo "Asegúrate de haber configurado el servicio systemd."
    exit 1
fi