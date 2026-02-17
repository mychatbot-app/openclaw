#!/bin/bash
set -euo pipefail

# Create GCS bucket for MyChatBot OpenClaw agent state persistence
# Usage: ./create-bucket.sh [PROJECT_ID]

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: No project ID. Pass as argument or set via: gcloud config set project YOUR_PROJECT"
  exit 1
fi

BUCKET_NAME="mcb-openclaw-state"
REGION="europe-west1"

echo "Project:  $PROJECT_ID"
echo "Bucket:   gs://$BUCKET_NAME"
echo "Region:   $REGION"
echo ""

# Create bucket
if gsutil ls "gs://$BUCKET_NAME" &>/dev/null; then
  echo "✅ Bucket gs://$BUCKET_NAME already exists"
else
  echo "Creating bucket..."
  gsutil mb -p "$PROJECT_ID" -l "$REGION" -b on "gs://$BUCKET_NAME"
  echo "✅ Bucket created"
fi

# Set lifecycle: delete objects older than 365 days (optional safety net)
echo ""
echo "Setting uniform bucket-level access..."
gsutil uniformbucketlevelaccess set on "gs://$BUCKET_NAME"

# Verify
echo ""
echo "Verifying..."
gsutil ls -L -b "gs://$BUCKET_NAME" | head -15
echo ""
echo "✅ Bucket gs://$BUCKET_NAME is ready"
echo ""
echo "Next: grant the Cloud Run service account access:"
echo "  gsutil iam ch serviceAccount:YOUR_SA@$PROJECT_ID.iam.gserviceaccount.com:objectAdmin gs://$BUCKET_NAME"
