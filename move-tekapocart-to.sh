#!/bin/sh

DOMAIN=xxxxx
OLD_PROJECT_ID=xxxxx
ADMIN_MAIL=xxxxx
DB_PASSWD=xxxxx
DB_RT_PASSWD=xxxxx

REGION=asia-east1
ZONE=$REGION-c
CONTAINER=standalone
NAME=$(echo $DOMAIN-$CONTAINER | tr . -)
REPO=asia.gcr.io/tekapocart/$CONTAINER

gcloud compute instances create-with-container $NAME \
    --image https://www.googleapis.com/compute/v1/projects/$OLD_PROJECT_ID/global/images/$NAME-image \
    --boot-disk-size 15GB \
    --boot-disk-type pd-ssd \
    --container-image $REPO \
    --container-env TC_DOMAIN=$DOMAIN \
    --container-env ADMIN_MAIL=$ADMIN_MAIL \
    --container-env DB_PASSWD=$DB_PASSWD \
    --container-env DB_RT_PASSWD=$DB_RT_PASSWD \
    --container-mount-host-path mount-path=/var/www,host-path=/var/www \
    --container-mount-host-path mount-path=/var/db,host-path=/var/db \
    --container-mount-host-path mount-path=/var/bak,host-path=/var/bak \
    --container-restart-policy never \
    --machine-type g1-small  \
    --tags http-server,https-server \
    --zone $ZONE
