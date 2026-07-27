# Tecnicas de Despliegue Automatico

Aplicacion Flask (Task Manager) con despliegue automatico en Microsoft Azure mediante CI/CD con GitHub Actions.

## Arquitectura

```
[GitHub] --(push)--> [GitHub Actions] --(deploy)--> [Azure App Service]
                                                       |
                                            [Flask + Gunicorn]
                                                       |
                                                  [SQLite]
```

### Componentes

| Componente | Tecnologia |
|---|---|
| App Web | Python Flask + Gunicorn |
| Base de datos | SQLite |
| CI/CD | GitHub Actions |
| Hosting | Azure App Service (Linux) |
| Proxy inverso | Nginx (en VM) |

## Estructura del proyecto

```
/
├── app.py                        # Aplicacion Flask
├── requirements.txt              # Dependencias Python
├── templates/index.html          # Interfaz web
├── static/style.css              # Estilos
├── .github/workflows/
│   ├── deploy.yml                # CI/CD a Azure App Service
│   └── deploy-vm.yml             # CI/CD a Azure VM (alternativa)
├── azure/
│   ├── setup-vm.ps1              # Script creacion VM Azure
│   └── setup-app.sh              # Configuracion del servidor
└── README.md
```

---

## Guia de despliegue

### Opcion 1: Azure App Service (Recomendada)

#### 1. Crear App Service en Azure

Desde Azure Portal o Azure CLI:

```bash
# Login en Azure
az login

# Crear Resource Group
az group create --name TecnicasDeployRG --location eastus

# Crear App Service Plan (gratuito F1 o basico B1)
az appservice plan create \
    --name tecnicas-plan \
    --resource-group TecnicasDeployRG \
    --sku F1 \
    --is-linux

# Crear Web App con Python 3.12
az webapp create \
    --name tecnicas-app \
    --resource-group TecnicasDeployRG \
    --plan tecnicas-plan \
    --runtime "PYTHON:3.12"
```

#### 2. Configurar despliegue continuo

```bash
# Obtener publish profile
az webapp deployment list-publishing-profiles \
    --name tecnicas-app \
    --resource-group TecnicasDeployRG \
    --xml
```

El XML obtenido se agrega como **secreto** en GitHub:
- Ir a Settings > Secrets and variables > Actions
- Crear secreto: `AZURE_PUBLISH_PROFILE`
- Crear variable: `AZURE_APP_NAME` = `tecnicas-app`

#### 3. Configurar startup de la app en Azure

```bash
az webapp config set \
    --name tecnicas-app \
    --resource-group TecnicasDeployRG \
    --startup-file "gunicorn --workers 3 --bind 0.0.0.0:8000 app:app"
```

#### 4. CI/CD automatico

Cada `git push` a `main` ejecuta el workflow `.github/workflows/deploy.yml` que:
1. Clona el repositorio
2. Instala dependencias Python
3. Verifica que la app cargue correctamente
4. Despliega a Azure App Service

---

### Opcion 2: Azure Virtual Machine (similar a EC2)

#### 1. Crear VM

Ejecutar el script PowerShell:
```powershell
.\azure\setup-vm.ps1
```

O crear manualmente:
```bash
az vm create \
    --resource-group TecnicasDeployRG \
    --name tecnicas-vm \
    --image Ubuntu2204 \
    --admin-username azureuser \
    --generate-ssh-keys \
    --size Standard_B1s

az vm open-port --port 80 --resource-group TecnicasDeployRG --name tecnicas-vm
```

#### 2. Configurar servidor

```bash
scp azure/setup-app.sh azureuser@<IP>:/home/azureuser/
ssh azureuser@<IP>
chmod +x setup-app.sh && ./setup-app.sh
```

#### 3. Configurar CI/CD

Agregar secrets en GitHub:
- `VM_HOST` = IP publica de la VM
- `VM_USER` = azureuser
- `VM_SSH_KEY` = contenido de la clave privada SSH

Cada `git push` ejecuta `.github/workflows/deploy-vm.yml` que:
1. Conecta via SSH a la VM
2. Hace `git pull`
3. Instala dependencias
4. Reinicia la app

---

## API REST

La aplicacion expone una API REST:

| Metodo | Ruta | Descripcion |
|---|---|---|
| GET | `/api/tasks` | Listar todas las tareas |
| POST | `/api/tasks` | Crear tarea (body JSON: `{"title": "..."}`) |
| PUT | `/api/tasks/<id>` | Actualizar tarea |
| DELETE | `/api/tasks/<id>` | Eliminar tarea |

---

## Prueba local

```bash
pip install -r requirements.txt
python app.py
# Abrir http://localhost:5000
```

---

## Pasos realizados

1. Creacion de aplicacion Flask con interfaz web y API REST
2. Configuracion de repositorio Git y subida a GitHub
3. Creacion de pipeline CI/CD con GitHub Actions
4. Creacion de scripts de infraestructura para Azure
5. Documentacion del proceso y arquitectura
