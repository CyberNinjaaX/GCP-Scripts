#!/bin/bash
set -e

echo "🚀 Starting GSP315 Challenge Lab setup..."

# Detect Project
PROJECT_ID=$(gcloud config get-value project)
echo "📌 Using Project: $PROJECT_ID"

# Detect default zone & region
DEFAULT_ZONE=$(gcloud config get-value compute/zone 2>/dev/null || echo "us-central1-a")
REGION=$(echo $DEFAULT_ZONE | sed 's/-[a-z]$//')   # us-central1-a -> us-central1
echo "🌍 Using Region: $REGION"

# Resources
BUCKET_NAME="${PROJECT_ID}-bucket"
TOPIC_NAME="gsp315-topic"
SUBSCRIPTION_NAME="gsp315-sub"
FUNCTION_NAME="gsp315-function"

# Create bucket
echo "📦 Creating storage bucket: ${BUCKET_NAME} in ${REGION}"
gcloud storage buckets create gs://${BUCKET_NAME} \
  --location=${REGION} \
  --project=${PROJECT_ID}

# Create Pub/Sub topic
echo "📡 Creating Pub/Sub topic: ${TOPIC_NAME}"
gcloud pubsub topics create ${TOPIC_NAME} --project=${PROJECT_ID}

# Create Pub/Sub subscription
echo "🔔 Creating Pub/Sub subscription: ${SUBSCRIPTION_NAME}"
gcloud pubsub subscriptions create ${SUBSCRIPTION_NAME} \
  --topic=${TOPIC_NAME} \
  --project=${PROJECT_ID}

# Create a Cloud Function (hello world)
echo "⚡ Deploying Cloud Function: ${FUNCTION_NAME}"
gcloud functions deploy ${FUNCTION_NAME} \
  --runtime=nodejs16 \
  --trigger-topic=${TOPIC_NAME} \
  --region=${REGION} \
  --entry-point=helloPubSub \
  --source=. \
  --project=${PROJECT_ID} \
  --quiet

echo "✅ GSP315 Setup Completed Successfully!"
