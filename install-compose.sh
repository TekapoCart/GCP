#!/bin/sh

while getopts d:e: option
    do
    case "${option}"
    in
        d) DOMAIN=${OPTARG};;
        e) EMAIL=${OPTARG};;
    esac
done

if [ -z "$IP" ]; then
    IP=$(cat .ip)
fi

if [ -z "$IP" ]; then
    echo "IP=123.123.123.123 sh install-compose.sh -d www.yoursite.com -e admin@example.com"
    echo "請輸入 IP"
    exit 1;
fi

if [ -z "$DOMAIN" ]; then
    echo "sh install-compose.sh -d www.yoursite.com -e admin@example.com"
    echo "請輸入商店網址"
    exit 1;
fi

if [ -z "$EMAIL" ]; then
    echo "sh install-compose.sh -d www.yoursite.com -e admin@example.com"
    echo "請輸入 E-Mail"
    exit 1;
fi

DB_RT_PASSWD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-16)
DB_PASSWD=$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-16)

REGION=asia-east1
ZONE=asia-east1-c
NAME=$(echo $DOMAIN-compose | tr . -)

# create http, https firewall rules
CHECK_HTTP=$(gcloud compute firewall-rules list | grep default-allow-http)
if [ ${#CHECK_HTTP} -eq 0 ]; then	
    gcloud compute firewall-rules create default-allow-http --allow tcp:80
    gcloud compute firewall-rules create default-allow-https --allow tcp:443
fi

# create instance
gcloud compute instances create $NAME  \
--boot-disk-size 10GB  \
--boot-disk-type pd-ssd  \
--image-family cos-stable  \
--image-project cos-cloud  \
--machine-type g1-small  \
--tags http-server,https-server  \
--zone $ZONE  \
--address $IP  \
--metadata TC_DOMAIN=$DOMAIN,ADMIN_MAIL=$EMAIL,DB_PASSWD=$DB_PASSWD,DB_RT_PASSWD=$DB_RT_PASSWD,\
startup-script='#! /bin/bash
TC_DOMAIN=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/TC_DOMAIN -H "Metadata-Flavor: Google")
ADMIN_MAIL=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/ADMIN_MAIL -H "Metadata-Flavor: Google")
DB_PASSWD=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/DB_PASSWD -H "Metadata-Flavor: Google")
DB_RT_PASSWD=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/DB_RT_PASSWD -H "Metadata-Flavor: Google")

if [ ! -d "/var/tekapo" ]; then
  mkdir /var/tekapo
  git clone https://github.com/TekapoCart/docker_compose.git /var/tekapo  
  sed -i "s/TC_DOMAIN=ToBeDefined/TC_DOMAIN=$TC_DOMAIN/g" /var/tekapo/.env
  sed -i "s/ADMIN_MAIL=ToBeDefined/ADMIN_MAIL=$ADMIN_MAIL/g" /var/tekapo/.env
  sed -i "s/DB_PASSWD=ToBeDefined/DB_PASSWD=$DB_PASSWD/g" /var/tekapo/.env
  sed -i "s/DB_RT_PASSWD=ToBeDefined/DB_RT_PASSWD=$DB_RT_PASSWD/g" /var/tekapo/.env
fi

if [ ! -d "/var/volumes" ]; then
  mkdir -p /var/volumes/html
  sudo chown -R 1001:1001 /var/volumes/html
fi

cd /var/tekapo
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:$PWD" \
  -w="$PWD" \
  docker/compose:latest pull
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:$PWD" \
  -w="$PWD" \
  docker/compose:latest up --force-recreate',\
shutdown-script='#! /bin/bash
cd /var/tekapo
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:$PWD" \
  -w="$PWD" \
  docker/compose:latest down'

CHECK_INSTANCE=$(gcloud compute instances list | grep $NAME)
if [ ${#CHECK_INSTANCE} -eq 0 ]; then	
    exit
fi

# create snapshot
gcloud beta compute resource-policies create snapshot-schedule $NAME-snapshot-schedule \
    --max-retention-days 14 \
    --start-time 14:00 \
    --hourly-schedule 6 \
    --on-source-disk-delete apply-retention-policy \
    --region $REGION \
    --storage-location asia

gcloud beta compute disks add-resource-policies $NAME \
    --resource-policies $NAME-snapshot-schedule \
    --zone $ZONE
