# Java EC2 Deploy — Prueba de Concepto

Prueba de concepto (PoC) que demuestra la **orquestación de servicios** y el **despliegue automatizado** de una aplicación Java en una instancia **Amazon EC2**, utilizando GitHub Actions como plataforma de integración y entrega continua (CI/CD).

---

## Descripción general

Este proyecto implementa un servidor HTTP ligero desarrollado en Java con el framework **Javalin**, empaquetado como un fat JAR mediante el plugin **Shadow JAR** de Gradle, y desplegado de forma automatizada a una máquina virtual EC2 que ejecuta Ubuntu. El ciclo de vida del servicio en producción es gestionado por **systemd**.

El objetivo principal es validar el flujo completo desde el código fuente hasta un servicio en ejecución en la nube, con una intervención manual mínima.

---

## Capacidades clave

| Capacidad | Descripción |
|-----------|-------------|
| **Compilación automatizada** | Gradle compila la aplicación y genera un fat JAR auto-contenido con todas sus dependencias. |
| **CI/CD con GitHub Actions** | El pipeline se activa automáticamente en cada push a `main`, o manualmente desde cualquier rama vía `workflow_dispatch`. |
| **Despliegue remoto seguro** | El JAR se transfiere a la instancia EC2 mediante SCP sobre SSH, usando credenciales almacenadas como Secrets de GitHub. |
| **Gestión del ciclo de vida del servicio** | Scripts de pre-deploy y post-deploy orquestan la detención, limpieza, arranque y verificación del servicio en la instancia remota. |
| **Servicio persistente con systemd** | La aplicación se ejecuta como un servicio de sistema (`myapp.service`) que se reinicia automáticamente en caso de fallo. |
| **Exposición en puerto 80** | Se utiliza `authbind` para que el proceso sin privilegios de root pueda enlazarse al puerto 80. |
| **API REST básica** | Expone endpoints GET y POST bajo la ruta `/users` como demostración de la capa de aplicación. |

---

## Tecnologías utilizadas

- **Java 21** (distribución Microsoft OpenJDK)
- **Javalin 6.7.0** — framework HTTP ligero para Java
- **Gradle 8.8** con el plugin `com.gradleup.shadow 8.3.8`
- **GitHub Actions** — automatización del pipeline CI/CD
- **Amazon EC2** (Ubuntu) — entorno de despliegue
- **systemd** — gestión del servicio en producción
- **authbind** — enlace a puertos privilegiados sin root

---

## Documentos clave

### `.github/workflows/deploy.yml`
Define el pipeline de CI/CD completo. Sus pasos son:

1. **Checkout** del código fuente (rama configurable).
2. **Configuración del JDK 21** con caché de Gradle.
3. **Compilación** con `./gradlew clean shadowjar`, generando el fat JAR.
4. **Pre-deploy remoto**: ejecuta el script `pre-deploy` en EC2 para detener el servicio activo y limpiar JARs anteriores.
5. **Transferencia del JAR** a `/opt/apps/backend/` en EC2 mediante SCP.
6. **Post-deploy remoto**: ejecuta el script `post-deploy` en EC2 para recargar systemd, iniciar el servicio y verificar su estado.

### `scripts_ubuntu/pre_deploy.sh`
Script de pre-despliegue que se ejecuta en la instancia EC2. Realiza:
- Detención del servicio `myapp.service` si se encuentra activo.
- Eliminación de los JARs anteriores en el directorio de la aplicación.

### `scripts_ubuntu/post_deploy.sh`
Script de post-despliegue que se ejecuta en la instancia EC2. Realiza:
- Recarga del demonio de systemd (`daemon-reload`).
- Inicio del servicio `myapp.service`.
- Verificación del estado del servicio; reporta éxito o imprime los últimos logs de error y devuelve código de salida no cero.

### `scripts_ubuntu/myapp.service`
Archivo de unidad de systemd que define cómo ejecutar la aplicación Java como servicio del sistema:
- Ejecuta el JAR más reciente encontrado en `/opt/apps/backend/` a través de `authbind`.
- Reinicia el servicio automáticamente en caso de fallo (`Restart=always`).
- Registra stdout y stderr en el journal de systemd.

### `app/build.gradle`
Archivo de construcción de Gradle. Configura:
- Dependencias principales: Javalin, Jackson Databind y Guava.
- Plugin Shadow JAR para generar el fat JAR con nombre `app_chida-1.0.0.jar`.
- Clase principal: `gradle_project.App`.

### `app/src/main/java/gradle_project/App.java`
Punto de entrada de la aplicación. Configura el servidor Javalin con el router de la API y lo inicia en el puerto 80.

---

## Arquitectura del flujo de despliegue

```
┌─────────────────────────────────────────────────┐
│               GitHub Actions Runner              │
│                                                 │
│  1. git checkout                                │
│  2. setup JDK 21                                │
│  3. ./gradlew clean shadowjar  ──►  app_chida-*.jar│
│  4. SSH pre-deploy  ──────────────────────────► │
│  5. SCP JAR  ──────────────────────────────────►│
│  6. SSH post-deploy  ──────────────────────────►│
└─────────────────────────────────────────────────┘
                                        │
                          ┌─────────────▼─────────────┐
                          │      Amazon EC2 (Ubuntu)   │
                          │                           │
                          │  /opt/apps/backend/       │
                          │      └── app_chida-*.jar  │
                          │                           │
                          │  systemd: myapp.service   │
                          │      └── java -jar (p.80) │
                          └───────────────────────────┘
```

---

## Endpoints de la API

| Método | Ruta     | Descripción                                 |
|--------|----------|---------------------------------------------|
| GET    | `/users` | Devuelve un mensaje de texto de ejemplo.    |
| POST   | `/users` | Recibe y devuelve un cuerpo JSON de prueba. |

---

## Secretos de GitHub requeridos

Para que el pipeline de despliegue funcione, se deben configurar los siguientes Secrets en el repositorio:

| Secret                | Descripción                                          |
|-----------------------|------------------------------------------------------|
| `EC2_HOST`            | Dirección IP pública o DNS de la instancia EC2.      |
| `EC2_USER`            | Usuario SSH de la instancia EC2 (p. ej. `ubuntu`).  |
| `EC2_SSH_PRIVATE_KEY` | Clave privada SSH para autenticación en la instancia.|

---

## Alcance de la prueba de concepto

Este proyecto **no** pretende ser una solución lista para producción. Su propósito es demostrar:

- La viabilidad de automatizar el ciclo de compilación y despliegue de un servicio Java en EC2 con herramientas estándar y de bajo costo.
- La orquestación del servicio remoto mediante scripts de shell y systemd.
- Un punto de partida replicable y extensible para proyectos con requisitos similares.

---

## Licencia

Consulta el archivo [LICENSE.md](LICENSE.md) para más información.
