# Configuración de Entorno

Este proyecto usa diferentes archivos de entorno (`.env`) para cada flavor:

## Archivos de Configuración

- **`.env.example`** - Plantilla de ejemplo (versionado en Git)
- **`.env.development`** - Configuración de desarrollo con servidor local (NO versionado)
- **`.env.production`** - Configuración de producción con servidor real (NO versionado)

## Uso

### Desarrollo (Servidor Local)
```bash
flutter run --flavor development
```
Carga `.env.development` con `BACKEND_URL` apuntando al servidor local de pruebas.

### Producción (Servidor Real)
```bash
flutter run --flavor production
```
Carga `.env.production` con `BACKEND_URL` apuntando al servidor de producción.

## Configuración Inicial

1. Copia `.env.example` a `.env.development` y `.env.production`:
   ```bash
   cp .env.example .env.development
   cp .env.example .env.production
   ```

2. Edita cada archivo con sus respectivas configuraciones:
   - `.env.development`: URL del servidor local y configuraciones de prueba
   - `.env.production`: URL del servidor de producción y configuraciones reales

## Variables de Entorno

Todas las configuraciones disponibles:

```bash
# API Backend
BACKEND_URL=http://tu-servidor.com/api

# URLs externas
TERMS_AND_CONDITIONS_URL=https://tu-sitio.com/terminos

# Contacto de soporte
SUPPORT_PHONE=03513040506
SUPPORT_WHATSAPP=5493513040506
```

## Seguridad

⚠️ **IMPORTANTE**: Los archivos `.env.development` y `.env.production` están en `.gitignore` y NO se suben al repositorio por seguridad.

Solo `.env.example` está versionado como plantilla de referencia.
