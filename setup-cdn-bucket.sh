#!/bin/sh

DOMAIN=shop.yoursite.com
PROJECT_ID=shop-yoursite-com

REGION=asia-east1
ZONE=$REGION-c
CONTAINER=standalone

VM=$(echo $DOMAIN-$CONTAINER | tr . -)
SERVICE_ACCOUNT=$(echo $DOMAIN-service-account | tr . -)
STORAGE_BUCKET=$(echo $DOMAIN-cdn | tr . -)

gcloud iam service-accounts create $SERVICE_ACCOUNT --display-name "TekapoCart CDN Storage Admin"

# add role storage.admin
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com --role roles/storage.admin

# get key
gcloud iam service-accounts keys create cdn_key.json \
    --iam-account $SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com

# create bucket and set public
gsutil mb -p $PROJECT_ID -c multi_regional -l asia gs://$STORAGE_BUCKET/
gsutil defacl ch -u AllUsers:R gs://$STORAGE_BUCKET
gsutil acl ch -u AllUsers:R gs://$STORAGE_BUCKET

# upload key to vm
gcloud compute scp cdn_key.json $VM:/tmp --zone $ZONE
gcloud compute ssh $VME --zone $ZONE --command 'sudo mv /tmp/cdn_key.json /var/bak && sudo chmod +r /var/bak/cdn_key.json'

# set metadata on already uploaded objects
gsutil -m setmeta -r -h "Cache-Control:public, max-age=604800" gs://$STORAGE_BUCKET/*
