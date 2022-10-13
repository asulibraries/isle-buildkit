#!/usr/bin/with-contenv bash
set -e

mkdir -p /home/ubuntu/.aws

cat << EOF > /home/ubuntu/.aws/credentials
[transcribe]
aws_access_key_id = $(cat /run/secrets/AWS_ACCESS_KEY_ID)
aws_secret_access_key = $(cat /run/secrets/AWS_SECRET_ACCESS_KEY)
EOF