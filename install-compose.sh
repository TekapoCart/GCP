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
REPO=https://github.com/TekapoCart/docker_compose.git

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

cd ~

if [ ! -d "certs" ]; then
  mkdir certs
# docker run --rm  -v ~/certs:/etc/letsencrypt -p 80:80 -ti certbot/certbot certonly --standalone --email $ADMIN_MAIL --agree-tos --preferred-challenges http -d $TC_DOMAIN
fi

if [ ! -d "tekapo" ]; then
  git clone $REPO tekapo
  mkdir -p ~/tekapo/volumes/html
  sudo chown 1001:1001 ~/tekapo/volumes/html
  sed -ie "s/TC_DOMAIN=ToBeDefined/TC_DOMAIN=$TC_DOMAIN/g" ~/tekapo/.env
  sed -ie "s/ADMIN_MAIL=ToBeDefined/ADMIN_MAIL=$ADMIN_MAIL/g" ~/tekapo/.env
  sed -ie "s/DB_PASSWD=ToBeDefined/DB_PASSWD=$DB_PASSWD/g" ~/tekapo/.env
  sed -ie "s/DB_RT_PASSWD=ToBeDefined/DB_RT_PASSWD=$DB_RT_PASSWD/g" ~/tekapo/.env
fi

cd ~/tekapo
docker run docker/compose:latest version
docker run --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
-v "$PWD:$PWD" \
-w="$PWD" \
docker/compose:latest pull
# docker run --rm \
#    -v /var/run/docker.sock:/var/run/docker.sock \
#    -v "$PWD:$PWD" \
#    -w="$PWD" \
#    docker/compose:latest up',\
shutdown-script='#! /bin/bash
cd ~/tekapo
docker run --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
-v "$PWD:$PWD" \
-w="$PWD" \
docker/compose:latest down'
