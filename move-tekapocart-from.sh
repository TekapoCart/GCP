#!/bin/sh

DOMAIN=xxxxx
OLD_PROJECT_ID=xxxxx
NEW_PROJECT_OWNER_MAIL=xxxx

REGION=asia-east1
ZONE=$REGION-c
CONTAINER=standalone
NAME=$(echo $DOMAIN-$CONTAINER | tr . -)

gcloud compute images create $NAME-image \
  --source-disk $NAME \
  --source-disk-zone $ZONE

gcloud projects add-iam-policy-binding $OLD_PROJECT_ID \
    --member user:$NEW_PROJECT_OWNER_MAIL --role roles/compute.imageUser
