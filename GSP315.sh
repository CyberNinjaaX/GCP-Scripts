#!/bin/bash
# 🚀 GSP315 Challenge Lab Automation Script
# Author: CyberNinjaaX
# Description: Automates common GCP resources for GSP315 lab

set -e

echo "🚀 Starting GSP315 Challenge Lab setup..."

# Variables
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-bucket"
TOPIC_NAME="gsp315-topic"
SUBSCRIPTION_NAME="gsp315-sub"
FUNCTION_NAME="gsp315-function"

echo "📦 Creating storage bucket: ${BUCKET_NAME}"
gcloud storage buckets create gs://${BUCKET_NAME} --location=${REGION} --project=${PROJECT_ID}

echo "📨 Creating Pub/Sub topic: ${TOPIC_NAME}"
gcloud pubsub topics create ${TOPIC_NAME} --project=${PROJECT_ID}

echo "🔔 Creating Pub/Sub subscription: ${SUBSCRIPTION_NAME}"
gcloud pubsub subscriptions create ${SUBSCRIPTION_NAME} \
  --topic=${TOPIC_NAME} \
  --project=${PROJECT_ID}

echo "⚡ Deploying Cloud Function: ${FUNCTION_NAME}"
gcloud functions deploy ${FUNCTION_NAME} \
  --runtime=nodejs18 \
  --trigger-topic=${TOPIC_NAME} \
  --entry-point=helloPubSub \
  --region=${REGION} \
  --project=${PROJECT_ID} \
  --allow-unauthenticated

echo "✅ GSP315 setup completed successfully!"
