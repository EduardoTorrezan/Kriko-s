#!/bin/bash
# Script para criação da VM e deploy do Kriko's na Google Cloud Compute Engine

set -e

echo "=== Deploy do Kriko's no Google Cloud Compute Engine ==="

# Verifica se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "Erro: gcloud CLI não foi encontrado. Execute este script no Cloud Shell ou com o Google Cloud SDK instalado."
    exit 1
fi

# Obter ou solicitar o Project ID
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$CURRENT_PROJECT" ] || [ "$CURRENT_PROJECT" = "(unset)" ]; then
    read -p "Digite o ID do seu Projeto Google Cloud: " GCP_PROJECT
    gcloud config set project "$GCP_PROJECT"
else
    GCP_PROJECT="$CURRENT_PROJECT"
    echo "Usando o projeto atual: $GCP_PROJECT"
fi

VM_NAME="krikos-server"
ZONE="us-central1-a"
MACHINE_TYPE="e2-micro"
DISK_SIZE="30GB"

echo "1. Habilitando a API da Compute Engine..."
gcloud services enable compute.googleapis.com

echo "2. Criando regra de firewall para tráfego HTTP..."
gcloud compute firewall-rules create allow-http-80 \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=http-server 2>/dev/null || echo "Regra de firewall já existe ou foi mantida."

echo "3. Criando a máquina virtual gratuita ($VM_NAME)..."
gcloud compute instances create "$VM_NAME" \
    --project="$GCP_PROJECT" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="ubuntu-2404-lts-amd64" \
    --image-project="ubuntu-os-cloud" \
    --boot-disk-size="$DISK_SIZE" \
    --boot-disk-type="pd-standard" \
    --tags="http-server" \
    --metadata-from-file="startup-script=startup.sh"

echo "4. Obtendo o IP externo da VM..."
IP_EXTERNO=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "========================================================"
echo " VM criada com sucesso!"
echo " IP Público: http://$IP_EXTERNO"
echo " O script de inicialização está instalando o PHP 8.4,"
echo " Apache, MariaDB e configurando o projeto."
echo " Aguarde cerca de 3 a 5 minutos e acesse no navegador:"
echo " -> http://$IP_EXTERNO"
echo " -> Painel: http://$IP_EXTERNO/painel.php"
echo " Usuário: admin@krikos.com | Senha: admin123"
echo "========================================================"
