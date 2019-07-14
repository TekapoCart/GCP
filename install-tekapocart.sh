#!/bin/sh

while getopts d:a:e: option
    do
    case "${option}"
    in
        d) DOMAIN=${OPTARG};;
        a) ADDRESS=${OPTARG};;
        e) EMAIL=${OPTARG};;
    esac
done

if [ -z "$DOMAIN" ]; then
    echo "請輸入商店網址 範例：sh install-tekapocart.sh -d www.yoursite.com -e admin@example.com -a xxx.xxx.xxx"
    exit 1;
fi

if [ -z "$EMAIL" ]; then
    echo "請輸入你的信箱（後台登入帳號） 範例：sh install-tekapocart.sh -d www.yoursite.com -e admin@example.com -a xxx.xxx.xxx"
    exit 1;
fi

if [ -z "$ADDRESS" ]; then
    echo "請輸入商店 IP 位址  範例：sh install-tekapocart.sh -d www.yoursite.com -e admin@example.com -a xxx.xxx.xxx"
    exit 1;
fi

DB_RT_PASSWD=$(openssl rand -base64 16)
DB_PASSWD=$(openssl rand -base64 16)

REGION=asia-east1
ZONE=asia-east1-c
CONTAINER=standalone
NAME=$(echo $DOMAIN-$CONTAINER | tr . -)
REPO=asia.gcr.io/tekapocart/$CONTAINER


# create http, https firewall rules
CHECK_HTTP=$(gcloud compute firewall-rules list | grep default-allow-http)
if [ ${#CHECK_HTTP} -eq 0 ]; then	
    gcloud compute firewall-rules create default-allow-http --allow tcp:80
fi

CHECK_HTTPS=$(gcloud compute firewall-rules list | grep default-allow-https)
if [ ${#CHECK_HTTPS} -eq 0 ]; then	
    gcloud compute firewall-rules create default-allow-https --allow tcp:443
fi

# create instance
gcloud compute instances create-with-container $NAME \
    --boot-disk-size 10GB \
    --boot-disk-type pd-ssd \
    --container-image $REPO \
    --container-env TC_DOMAIN=$DOMAIN \
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
    --address $ADDRESS

CHECK_INSTANCE=$(gcloud compute instance list | grep $NAME)
if [ ${#CHECK_INSTANCE} -eq 0 ]; then	
    exit
fi

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
