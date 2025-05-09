

# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

echo "Please set the below values correctly"
read -p "${YELLOW}${BOLD}Enter the CLUSTER_NAME: ${RESET}" CLUSTER_NAME

# Export variables after collecting input
export CLUSTER_NAME 

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")


PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

sleep 60

#!/bin/bash

echo "$CLUSTER_NAME"
echo "$ZONE"
echo "$REGION"

cluster_function() {
  gcloud dataproc clusters create "$CLUSTER_NAME" \
    --region "$REGION" \
    --zone "$ZONE" \
    --master-machine-type n1-standard-2 \
    --worker-machine-type n1-standard-2 \
    --num-workers 2 \
    --worker-boot-disk-size 100 \
    --worker-boot-disk-type pd-standard \
    --no-address
}

cp_success=false

while [ "$cp_success" = false ]; do
  cluster_function
  exit_status=$?

  if [ "$exit_status" -eq 0 ]; then
    echo "Function deployed successfully [https://www.youtube.com/@techcps]"
    cp_success=true
  else
    echo "Cluster creation failed. Checking if cluster already exists..."

    if gcloud dataproc clusters describe "$CLUSTER_NAME" --region "$REGION" &>/dev/null; then
      echo "Cluster already exists. Deleting. [https://www.youtube.com/@techcps]"
      gcloud dataproc clusters delete "$CLUSTER_NAME" --region "$REGION" --quiet
      echo "Cluster deleted. Retrying in 10 seconds..."
    else
      echo "Unknown errors. Retrying in 10 seconds[https://www.youtube.com/@techcps]"
    fi
    echo "Please subscribe to techcps [https://www.youtube.com/@techcps]"
    sleep 10
  fi
done


gcloud dataproc jobs submit spark \
    --project $DEVSHELL_PROJECT_ID \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --class org.apache.spark.examples.SparkPi \
    --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000


echo "Click this link to open" "${YELLOW}${BOLD}https://console.cloud.google.com/dataproc/jobs?project=$DEVSHELL_PROJECT_ID${RESET}"

