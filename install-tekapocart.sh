#!/bin/sh

while [[ $# -gt 0 ]]
do
    key="${1}"
    case ${key} in
    --shop-url)
        DOMAIN="${2}"
        shift
        shift
        ;;
    --admin-mail)
        ADMIN_MAIL="${2}"
        shift
        shift
        ;;
    *)
        shift
        ;;
    esac
    shift
done

DB_RT_PASSWD=$(openssl rand -base64 16)
DB_PASSWD=$(openssl rand -base64 16)

REGION=asia-east1
ZONE=asia-east1-c
NAME=$(echo $DOMAIN | tr . -)
REPO=asia.gcr.io/tekapocart/standalone

gcloud compute instances create-with-container $NAME \
    --boot-disk-size 10GB \
    --boot-disk-type pd-ssd \
    --container-image $REPO \
    --container-env TC_DOMAIN=$DOMAIN \
    --container-env ADMIN_MAIL=$ADMIN_MAIL \
    --container-env DB_PASSWD=$DB_PASSWD \
    --container-env DB_RT_PASSWD=$DB_RT_PASSWD \
    --container-mount-host-path mount-path=/var/www,host-path=/var/www \
    --container-mount-host-path mount-path=/var/bak,host-path=/var/bak \
    --container-mount-host-path mount-path=/var/db,host-path=/var/db \
    --container-restart-policy never \
    --machine-type g1-small  \
    --tags http-server,https-server \
    --zone $ZONE

gcloud beta compute resource-policies create-snapshot-schedule $NAME-snapshot-schedule \
    --max-retention-days 14 \
    --start-time 14:00 \
    --hourly-schedule 12 \
    --on-source-disk-delete apply-retention-policy \
    --region $REGION \
    --storage-location asia

gcloud beta compute disks add-resource-policies $NAME \
    --resource-policies $VM_NAME-snapshot-schedule \
    --zone $ZONE
