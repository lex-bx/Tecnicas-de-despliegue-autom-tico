# Informe de Despliegue Automatico en Microsoft Azure

**Asignatura:** Tecnicas de Despliegue Automatico
**Plataforma:** Microsoft Azure (App Service)
**Aplicacion:** Task Manager (Python Flask)
**Repositorio:** https://github.com/lex-bx/Tecnicas-de-despliegue-autom-tico

---

## 1. Arquitectura del despliegue

```
[Desarrollador]
      |
      | git push
      v
[GitHub Repository]
      |
      | trigger automatico
      v
[GitHub Actions (CI/CD)]
      |
      | deploy
      v
[Azure App Service (Linux)]
      |
      |-- Gunicorn (WSGI server)
      |-- Flask (Aplicacion)
      |-- SQLite (Base de datos)
```

### Componentes

| Componente | Tecnologia |
|---|---|
| Aplicacion | Python 3.12 + Flask 3.1 |
| Servidor WSGI | Gunicorn |
| Base de datos | SQLite (modo WAL) |
| Control de versiones | Git + GitHub |
| CI/CD | GitHub Actions |
| Hosting | Azure App Service (Linux, Plan F1 Gratis) |
| Proxy | Nginx (integrado en App Service) |

---

## 2. Creacion y configuracion de recursos en Azure

### 2.1 App Service

Se creo un **App Service** en Azure Portal con los siguientes parametros:

- **Nombre:** `tecnicas-app-cano`
- **Grupo de recursos:** `tecnicas-app-cano_group`
- **Runtime:** Python 3.12
- **Sistema operativo:** Linux
- **Plan:** F1 (Gratis) - 1 GB de memoria, 60 minutos de CPU/dia
- **Region:** East US
- **URL:** https://tecnicas-app-cano-a0fdeqbgfaecfjd4.eastus-01.azurewebsites.net

### 2.2 Configuracion de la aplicacion

Se configuro el comando de inicio en Azure Portal:

```
gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 4 app:app
```

### 2.3 Autenticacion basica para despliegue

Se habilito la autenticacion basica de SCM y FTP para permitir el despliegue desde GitHub Actions.

---

## 3. Estructura del proyecto

```
/
├── app.py                        # Aplicacion Flask
├── requirements.txt              # Dependencias
├── test_app.py                   # Pruebas automaticas
├── templates/index.html          # Interfaz web
├── static/style.css              # Estilos
├── .github/workflows/
│   ├── deploy.yml                # CI/CD a Azure App Service
│   └── deploy-vm.yml             # CI/CD a Azure VM (alternativa)
├── azure/
│   ├── setup-vm.ps1              # Script para crear VM en Azure
│   └── setup-app.sh              # Configuracion del servidor en VM
└── README.md                     # Documentacion
```

---

## 4. Proceso de Integracion y Despliegue Continuo (CI/CD)

### 4.1 Workflow de GitHub Actions

El archivo `.github/workflows/deploy.yml` define el pipeline automatico:

```yaml
name: Deploy to Azure App Service

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - Checkout del codigo
      - Configurar Python 3.12
      - Instalar dependencias (pip install -r requirements.txt)
      - Ejecutar pruebas (test_app.py)
      - Desplegar a Azure App Service
```

### 4.2 Flujo de trabajo

1. El desarrollador hace `git push` a la rama `main`
2. GitHub Actions se activa automaticamente
3. Se clona el repositorio en un runner de Ubuntu
4. Se instala Python 3.12 y las dependencias
5. Se ejecutan las pruebas unitarias (test_app.py)
6. Si las pruebas pasan, se despliega a Azure App Service
7. Azure App Service detecta el cambio, reinicia la aplicacion y sirve la nueva version

### 4.3 Secretos de GitHub configurados

| Secreto/Variable | Proposito |
|---|---|
| `AZURE_PUBLISH_PROFILE` | Credenciales de despliegue (XML del perfil de publicacion) |
| `AZURE_APP_NAME` | Nombre del App Service (`tecnicas-app-cano`) |

---

## 5. Funcionamiento de la aplicacion

### 5.1 Interfaz web

La aplicacion permite:
- Agregar tareas con titulo y descripcion
- Marcar tareas como completadas
- Eliminar tareas

### 5.2 API REST

| Metodo | Ruta | Descripcion |
|---|---|---|
| GET | `/api/tasks` | Listar todas las tareas |
| POST | `/api/tasks` | Crear tarea (JSON: `{"title": "...", "description": "..."}`) |
| PUT | `/api/tasks/<id>` | Actualizar tarea (campos: title, description, completed) |
| DELETE | `/api/tasks/<id>` | Eliminar tarea |

### 5.3 Verificacion de funcionamiento

Se verifico que la aplicacion responde correctamente:

```bash
# Prueba GET
curl -s https://tecnicas-app-cano-a0fdeqbgfaecfjd4.eastus-01.azurewebsites.net/api/tasks

# Prueba POST
curl -s -X POST https://tecnicas-app-cano-a0fdeqbgfaecfjd4.eastus-01.azurewebsites.net/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "description": "Funciona"}'

# Resultado esperado: HTTP 200/201 con respuesta JSON
```

---

## 6. Entregables

| Elemento | Enlace / Ubicacion |
|---|---|
| Repositorio | https://github.com/lex-bx/Tecnicas-de-despliegue-autom-tico |
| URL publica | https://tecnicas-app-cano-a0fdeqbgfaecfjd4.eastus-01.azurewebsites.net |
| Workflow CI/CD | `.github/workflows/deploy.yml` |
| Documentacion | `README.md` e `informe-despliegue.md` |

---

## 7. Pasos resumidos

1. Creacion de aplicacion Flask con tareas (CRUD)
2. Inicializacion de repositorio Git y subida a GitHub
3. Creacion de App Service en Azure Portal (Plan F1 Gratis)
4. Obtencion del perfil de publicacion de Azure
5. Configuracion de secretos en GitHub
6. Configuracion del comando de inicio (gunicorn)
7. Push a GitHub activa el CI/CD automaticamente
8. Verificacion de la aplicacion funcionando en la URL publica

---

## 8. Capturas de evidencias

Las siguientes evidencias se encuentran disponibles en el repositorio y en la presentacion:

- Workflow de GitHub Actions ejecutado exitosamente
- Aplicacion funcionando en Azure (respuesta HTTP 200)
- API REST operativa (creacion y consulta de tareas)
- Configuracion del App Service en Azure Portal

---

**Elaborado para:** Exposicion grupal - Tecnicas de Despliegue Automatico
**Fecha:** Julio 2026
