#!/bin/bash
set -e

BUCKET="$1"
KEY="$2"

echo "[1/6] Install dependencies"
sudo yum install -y unzip nginx awscli || true

echo "[2/6] Download release from S3"
rm -rf /tmp/release && mkdir -p /tmp/release
aws s3 cp "s3://${BUCKET}/${KEY}" /tmp/release/release.zip

echo "[3/6] Unzip"
unzip -o /tmp/release/release.zip -d /tmp/release/app

echo "[4/6] Replace nginx content"
sudo rm -rf /usr/share/nginx/html/*
sudo cp -r /tmp/release/app/ec2-app/* /usr/share/nginx/html/

echo "[5/6] Restart nginx"
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "[6/6] Validate with retries"
for i in {1..10}; do
  if curl -f http://localhost/ >/dev/null 2>&1; then
    echo "✅ Deploy succeeded"
    exit 0
  fi
  echo "Waiting for nginx... ($i/10)"
  sleep 2
done

echo "❌ Validation failed"
exit 1
