#!/bin/bash

helpFunction()
{
   echo ""
   echo "Uso: $0 -s turbonomicsc -r TurboRole"
   echo -e "\t-s Nombre de la cuenta de servicio para Turbonomic"
   echo -e "\t-r Nombre del rol de Turbonomic en GCP"
   exit 1 # Exit script after printing help
}

while getopts "s:r:" opt
do
   case "$opt" in
      s ) serviceaccount="$OPTARG" ;;
      r ) turborole="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$serviceaccount" ] || [ -z "$turborole" ]
then
   echo "Alguno de los parámetros está vacío";
   helpFunction
fi

# Paso 0: configuración de nombres:
echo "La cuenta de servicios será: $serviceaccount"
echo "El role será: $turborole"


#Paso 1: obtener ID del projecto:

echo "capturando ID del projecto..."
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
if [ -z "$PROJECT_ID" ]; 
  then 
    #echo "NULL"; 
    echo "ERROR: No se puede obtener el ID del Proyecto. Revise los permisos de su cuenta o el estado del proyecto en GCP"
    exit 1
  else 
    echo "el ID del proyecto es: $PROJECT_ID"; 
fi

# Paso 2: Habilitar APIs en el proyecto:

echo "Habilitando APIs: Cloud Billing API, Cloud Resource Manager API, BigQuery API, Compute Engine API..."

gcloud services enable cloudbilling.googleapis.com cloudresourcemanager.googleapis.com bigquery.googleapis.com compute.googleapis.com


#Paso 2: crear cuenta de servicio
# comprobando si la cuenta de servicio ya existe

export sa=$(gcloud iam service-accounts keys list --iam-account=$serviceaccount@$PROJECT_ID.iam.gserviceaccount.com 2> /dev/null)
if [ -z "$sa" ]; 
  then 
    #echo "NULL";
    echo "La cuenta de servicio $serviceaccount no existe"
    echo "Creando cuenta de servicio "
    gcloud iam service-accounts create $serviceaccount
  else 
    echo "La cuenta $serviceaccount ya existe";
fi

#Paso 4: Generar el Key file
echo "Generando key file turbokf.json"
sleep 5
gcloud iam service-accounts keys create turbokf.json --iam-account=$serviceaccount@$PROJECT_ID.iam.gserviceaccount.com

#Paso 5: Crear el rol a nivel de proyecto


export role=$(gcloud iam roles describe $turborole --project=$PROJECT_ID 2> /dev/null)
if [ -z "$role" ]; 
then
echo "El rol $role no existe"
echo "Creando rol de lectura sobre el proyecto"
gcloud iam roles create $turborole --project=$PROJECT_ID \
  --title='Turbonomic Role: Min Access - Project' \
  --description='Minimum permissions to manage the Google Cloud project' \
  --permissions="compute.commitments.list,\
compute.disks.get,\
compute.disks.list,\
compute.diskTypes.list,\
compute.instances.get,\
compute.instances.list,\
compute.instanceGroupManagers.get,\
compute.instanceGroupManagers.list,\
compute.instanceGroups.get,\
compute.instanceGroups.list,\
compute.machineTypes.get,\
compute.machineTypes.list,\
compute.regions.list,\
compute.zones.list,\
container.clusters.get,\
logging.logEntries.list,\
logging.views.get,\
logging.views.list,\
monitoring.services.get,\
monitoring.services.list,\
monitoring.timeSeries.list,\
resourcemanager.projects.get,\
serviceusage.services.get" --stage=ALPHA
  
  else 
    echo "El rol ya existe en el proyecto"
    echo "Actualizando rol de lectura sobre el proyecto"
    gcloud iam roles update $turborole --project=$PROJECT_ID \
    --title='Turbonomic Role: Min Access - Project' \
  --description='Minimum permissions to manage the Google Cloud project' \
  --permissions="compute.commitments.list,\
compute.disks.get,\
compute.disks.list,\
compute.diskTypes.list,\
compute.instances.get,\
compute.instances.list,\
compute.instanceGroupManagers.get,\
compute.instanceGroupManagers.list,\
compute.instanceGroups.get,\
compute.instanceGroups.list,\
compute.machineTypes.get,\
compute.machineTypes.list,\
compute.regions.list,\
compute.zones.list,\
container.clusters.get,\
logging.logEntries.list,\
logging.views.get,\
logging.views.list,\
monitoring.services.get,\
monitoring.services.list,\
monitoring.timeSeries.list,\
resourcemanager.projects.get,\
serviceusage.services.get" --stage=ALPHA

fi


#Paso 6: Asignar el role a nivel de proyecto
echo "Asignando rol a cuenta de servicio $serviceaccount"
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$serviceaccount@$PROJECT_ID.iam.gserviceaccount.com --role=projects/$PROJECT_ID/roles/$turborole


#Paso 7: Descargar el key file
echo "Iniciando descarga de key file"
cloudshell download turbokf.json
echo "proceso completado"