#!/bin/bash

echo "Deteniendo la aplicación..."
sudo pkill -f "java -jar /opt/apps/backend/app*.jar"

echo "Eliminando JAR antiguos..."
find /opt/apps/backend -name "app*.jar" -type f -delete

echo "Predeploy completado"