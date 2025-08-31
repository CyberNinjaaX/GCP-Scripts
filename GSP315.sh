#!/bin/bash
# GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab
# Author: Your Name
# ⚠️ Use ONLY inside Qwiklabs temporary project

set -e

echo "🚀 Starting GSP315 Challenge Lab setup..."

# Variables (change if lab gives specific REGION/ZONE)
REGION="us-central1"
ZONE="us-central1-a"
BUCKET_NAME="Bucket Name"
TOPIC_NAME="Topic Name"
FUNCTION_NAME="Cloud Run Function Name"

# Task 1: Create a bucket
echo "📦 Creating storage bucket: $BUCKET_NAME"
gcloud storage buckets create gs://$BUCKET_NAME --location=$REGION

# Task 2: Create a Pub/Sub topic
echo "🔔 Creating Pub/Sub topic: $TOPIC_NAME"
gcloud pubsub topics create $TOPIC_NAME

# Task 3: Deploy the Cloud Run Function
echo "⚡ Deploying Cloud Run Function: $FUNCTION_NAME"

mkdir -p ~/gsp315_function && cd ~/gsp315_function

# Create index.js
cat > index.js <<'EOF'
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('Cloud_Run_Function_Name', async cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${JSON.stringify(event)}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = "Topic_Name";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1);

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      const newFilename = `${filename_without_ext}_64x64_thumbnail.${filename_ext}`;
      const gcsNewObject = bucket.file(newFilename);

      try {
        const [buffer] = await gcsObject.download();
        const resizedBuffer = await sharp(buffer)
          .resize(64, 64, {
            fit: 'inside',
            withoutEnlargement: true,
          })
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer, {
          metadata: {
            contentType: `image/${filename_ext}`,
          },
        });

        console.log(`Success: ${fileName} → ${newFilename}`);

        await pubsub
          .topic(topicName)
          .publishMessage({ data: Buffer.from(newFilename) });

        console.log(`Message published to ${topicName}`);
      } catch (err) {
        console.error(`Error: ${err}`);
      }
    } else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  } else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
EOF

# Create package.json
cat > package.json <<'EOF'
{
 "name": "thumbnails",
 "version": "1.0.0",
 "description": "Create Thumbnail of uploaded image",
 "scripts": {
   "start": "node index.js"
 },
 "dependencies": {
   "@google-cloud/functions-framework": "^3.0.0",
   "@google-cloud/pubsub": "^2.0.0",
   "@google-cloud/storage": "^6.11.0",
   "sharp": "^0.32.1"
 }
}
EOF

# Deploy function (2nd gen, Node.js 22)
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs22 \
  --region=$REGION \
  --entry-point=Cloud_Run_Function_Name \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=$BUCKET_NAME" \
  --source=. \
  --quiet

cd ~

# Task 4: Remove the previous engineer
echo "👤 Removing old user..."
OLD_USER=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format="value(bindings.members)" | grep "user:" | grep -v "$(gcloud config get-value account)" || true)

if [ -n "$OLD_USER" ]; then
  gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="$OLD_USER" \
    --role="roles/viewer" \
    --quiet
  echo "✅ Removed old engineer: $OLD_USER"
else
  echo "ℹ️ No extra users found to remove."
fi

echo "🎉 GSP315 Challenge Lab setup completed!"
