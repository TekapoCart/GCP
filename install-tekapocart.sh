#!/bin/sh

while getopts d:e:w:x:y:z option
    do
    case "${option}"
    in
        d) DOMAIN=${OPTARG};;
        e) EMAIL=${OPTARG};;
        w) SUITE=${OPTARG};;
        x) DOMAIN_2=${OPTARG};;
        y) DOMAIN_3=${OPTARG};; 
        z) DOMAIN_4=${OPTARG};;        
    esac
done

IP=$(cat .ip)

if [ -z "$IP" ]; then
    echo "IP=123.123.123.123 sh install-tekapocart.sh -d www.yoursite.com -e admin@example.com"
    echo "請輸入 IP"
    exit 1;
fi

if [ -z "$DOMAIN" ]; then
    echo "sh install-tekapocart.sh -d www.yoursite.com -e admin@example.com"
    echo "請輸入商店網址"
    exit 1;
fi

if [ -z "$EMAIL" ]; then
    echo "sh install-tekapocart.sh -d www.yoursite.com -e admin@example.com"
    echo "請輸入 E-Mail"
    exit 1;
fi

DB_RT_PASSWD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-16)
DB_PASSWD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-16)

REGION=asia-east1
ZONE=asia-east1-c
CONTAINER=standalone:1.0.3
NAME=$(echo $DOMAIN-$CONTAINER | tr . -)
REPO=asia.gcr.io/tekapocart/$CONTAINER


# create http, https firewall rules
CHECK_HTTP=$(gcloud compute firewall-rules list | grep default-allow-http)
if [ ${#CHECK_HTTP} -eq 0 ]; then	
    gcloud compute firewall-rules create default-allow-http --allow tcp:80
    gcloud compute firewall-rules create default-allow-https --allow tcp:443
fi

# create instance
gcloud compute instances create-with-container $NAME \
    --boot-disk-size 15GB \
    --boot-disk-type pd-ssd \
    --container-image $REPO \
    --container-env TC_ENABLE_SUITE=$SUITE \
    --container-env TC_DOMAIN=$DOMAIN \
    --container-env TC_DOMAIN_2=$DOMAIN_2 \
    --container-env TC_DOMAIN_3=$DOMAIN_3 \
    --container-env TC_DOMAIN_4=$DOMAIN_4 \
    --container-env ADMIN_MAIL=$EMAIL \
    --container-env DB_PASSWD=$DB_PASSWD \
    --container-env DB_RT_PASSWD=$DB_RT_PASSWD \
    --container-mount-host-path mount-path=/var/www,host-path=/var/www \
    --container-mount-host-path mount-path=/var/bak,host-path=/var/bak \
    --container-mount-host-path mount-path=/var/db,host-path=/var/db \
    --container-restart-policy never \
    --machine-type g1-small  \
    --tags http-server,https-server \
    --zone $ZONE \
    --address $IP

CHECK_INSTANCE=$(gcloud compute instances list | grep $NAME)
if [ ${#CHECK_INSTANCE} -eq 0 ]; then	
    exit
fi

# create snapshot
gcloud beta compute resource-policies create snapshot-schedule $NAME-snapshot-schedule \
    --max-retention-days 14 \
    --start-time 14:00 \
    --hourly-schedule 12 \
    --on-source-disk-delete apply-retention-policy \
    --region $REGION \
    --storage-location asia

gcloud beta compute disks add-resource-policies $NAME \
    --resource-policies $NAME-snapshot-schedule \
    --zone $ZONE
