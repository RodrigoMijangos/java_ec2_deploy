#!/bin/bash

# --- CONFIGURACIÓN ---
APP_URL="http://localhost:7000/health" # Ajusta si tu app está en HTTPS o en otro puerto
# Si usas HTTPS con certificados autofirmados, puede que necesites -k en curl
# APP_URL="https://localhost/health"

DISCORD_WEBHOOK_URL="TU_URL_DE_WEBHOOK_DE_DISCORD_AQUI" # ¡REEMPLAZA ESTO!
CRON_SCHEDULE="*/1 * * * *" # Frecuencia del cron job (cada 1 minuto)

LOG_DIR="/var/log/app_monitor"
STATUS_FILE="$LOG_DIR/app_last_active.timestamp" # Guarda el timestamp de la última vez que la app estuvo activa
CRON_DISABLED_FLAG="$LOG_DIR/cron_disabled.flag" # Archivo para indicar que el cron está deshabilitado
MONITOR_LOG="$LOG_DIR/monitor_log.txt" # Log de la actividad del script
CRONTAB_ENTRY="/etc/cron.d/myapp_monitor_cron" # Archivo para la entrada de cron (más fácil de manejar programáticamente)

CURL_BIN="/usr/bin/curl"
SYSTEMCTL_BIN="/usr/bin/systemctl"
GREP_BIN="/usr/bin/grep"
DATE_BIN="/usr/bin/date"
RM_BIN="/usr/bin/rm"
TOUCH_BIN="/usr/bin/touch"
ECHO_BIN="/usr/bin/echo"

# --- FUNCIONES ---

# Función para enviar mensaje a Discord
send_discord_message() {
    local message="$1"
    "$CURL_BIN" -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"$message\"}" \
         "$DISCORD_WEBHOOK_URL"
}

# Función para deshabilitar el cron job
disable_cron_job() {
    "$RM_BIN" -f "$CRONTAB_ENTRY" # Elimina el archivo que define el cron job
    "$TOUCH_BIN" "$CRON_DISABLED_FLAG" # Crea un archivo flag para indicar que está deshabilitado
    "$ECHO_BIN" "$($DATE_BIN +"%Y-%m-%d %H:%M:%S") - Cron job deshabilitado y flag creado." >> "$MONITOR_LOG"
}

# Función para habilitar el cron job (crea o recrea el archivo de cron)
enable_cron_job() {
    # Crea o sobrescribe el archivo de cron
    "$ECHO_BIN" "$CRON_SCHEDULE root $0 >> $MONITOR_LOG 2>&1" | sudo tee "$CRONTAB_ENTRY" > /dev/null
    sudo chmod 644 "$CRONTAB_ENTRY" # Permisos recomendados para archivos en /etc/cron.d/
    sudo "$RM_BIN" -f "$CRON_DISABLED_FLAG" # Elimina el flag de deshabilitado
    "$ECHO_BIN" "$($DATE_BIN +"%Y-%m-%d %H:%M:%S") - Cron job habilitado y flag eliminado." >> "$MONITOR_LOG"
}

# --- LÓGICA PRINCIPAL ---

# Asegurarse de que el directorio de logs exista
sudo mkdir -p "$LOG_DIR"
sudo chown "$USER":"$(id -gn)" "$LOG_DIR" # Asegura que el usuario que corre el script pueda escribir

# Si el flag de deshabilitado existe, salimos (el cron está deshabilitado)
if [ -f "$CRON_DISABLED_FLAG" ]; then
    "$ECHO_BIN" "$($DATE_BIN +"%Y-%m-%d %H:%M:%S") - Script ejecutado pero cron deshabilitado por flag." >> "$MONITOR_LOG"
    exit 0
fi

# 1. Verificar el estado de la aplicación
RESPONSE_CODE=$("$CURL_BIN" -s -o /dev/null -w "%{http_code}" "$APP_URL")
CURRENT_TIMESTAMP=$($DATE_BIN +%s)
CURRENT_DATETIME=$($DATE_BIN +"%Y-%m-%d %H:%M:%S")

if [ "$RESPONSE_CODE" == "200" ]; then
    # La aplicación está activa, actualizar el timestamp de última actividad
    "$ECHO_BIN" "$CURRENT_TIMESTAMP" > "$STATUS_FILE"
    "$ECHO_BIN" "$CURRENT_DATETIME - OK. App is running." >> "$MONITOR_LOG"
else
    # La aplicación no está respondiendo
    "$ECHO_BIN" "$CURRENT_DATETIME - FAILED. App is NOT running (HTTP Status: $RESPONSE_CODE)." >> "$MONITOR_LOG"

    # Si hay un timestamp de última actividad, calculamos la duración del uptime
    if [ -f "$STATUS_FILE" ]; then
        LAST_ACTIVE_TIMESTAMP=$(cat "$STATUS_FILE")
        UPTIME_SECONDS=$((CURRENT_TIMESTAMP - LAST_ACTIVE_TIMESTAMP))

        # Convertir segundos a formato HH:MM:SS
        HOURS=$((UPTIME_SECONDS / 3600))
        MINUTES=$(((UPTIME_SECONDS % 3600) / 60))
        SECONDS=$((UPTIME_SECONDS % 60))
        
        UPTIME_FORMATTED=$(printf "%02d horas, %02d minutos, %02d segundos" $HOURS $MINUTES $SECONDS)

        MESSAGE="⚠️ **ALERTA: Aplicación Javalin Caída** ⚠️\n"
        MESSAGE+="> **Última vez activa:** $($DATE_BIN -d "@$LAST_ACTIVE_TIMESTAMP" +"%Y-%m-%d %H:%M:%S") UTC\n"
        MESSAGE+="> **Tiempo activa:** $UPTIME_FORMATTED\n"
        MESSAGE+="> **Detectado caído el:** $CURRENT_DATETIME UTC (Estado HTTP: $RESPONSE_CODE)\n"
        MESSAGE+="> Monitoreo detenido. Por favor, realice un despliegue para reactivarlo."

        send_discord_message "$MESSAGE"
        
        # Eliminar el archivo de estado para reiniciar el contador en el próximo despliegue
        "$RM_BIN" -f "$STATUS_FILE"
    else
        MESSAGE="⚠️ **ALERTA: Aplicación Javalin Caída** ⚠️\n"
        MESSAGE+="> **Detectado caído el:** $CURRENT_DATETIME UTC (Estado HTTP: $RESPONSE_CODE)\n"
        MESSAGE+="> No se pudo determinar el tiempo activo previo. Monitoreo detenido."
        send_discord_message "$MESSAGE"
    fi
    
    # Deshabilitar el cron job para evitar más alertas hasta el próximo despliegue
    disable_cron_job
fi