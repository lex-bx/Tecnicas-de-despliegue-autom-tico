# Script de configuracion de Azure VM (alternativa a App Service)
# Requiere: Azure CLI instalado y sesion iniciada (az login)

param(
    [string]$ResourceGroup = "TecnicasDeployRG",
    [string]$Location = "eastus",
    [string]$VmName = "tecnicas-vm",
    [string]$AdminUser = "azureuser"
)

Write-Host "=== Configuracion de recursos Azure ===" -ForegroundColor Green

# Crear Resource Group
az group create --name $ResourceGroup --location $Location

# Crear VM (Ubuntu)
Write-Host "Creando VM Ubuntu..." -ForegroundColor Yellow
az vm create `
    --resource-group $ResourceGroup `
    --name $VmName `
    --image Ubuntu2204 `
    --admin-username $AdminUser `
    --generate-ssh-keys `
    --size Standard_B1s `
    --public-ip-sku Standard

# Abrir puerto 80 (HTTP)
az vm open-port `
    --resource-group $ResourceGroup `
    --name $VmName `
    --port 80

# Obtener IP publica
$IP = az vm show -d -g $ResourceGroup -n $VmName --query publicIps -o tsv
Write-Host "VM creada. IP Publica: $IP" -ForegroundColor Green

# Ejecutar script de configuracion en la VM
Write-Host "Configurando servidor..." -ForegroundColor Yellow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptContent = Get-Content -Raw "$ScriptDir\setup-app.sh"
az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VmName `
    --command-id RunShellScript `
    --scripts "$ScriptContent"

Write-Host "=== Configuracion completada ===" -ForegroundColor Green
Write-Host "Accede a la aplicacion en: http://$IP" -ForegroundColor Cyan
