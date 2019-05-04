
DOMAIN=shop.yoursite.com

REGION=asia-east1
ZONE=$REGION-c
NAME=$(echo $DOMAIN-db | tr . -)
TIER=db-f1-micro #https://cloud.google.com/sql/pricing#2nd-gen-pricing

DB_RT_PASSWD=$(openssl rand -base64 16)
DB_PASSWD=$(openssl rand -base64 16)

gcloud sql instances create $NAME \
    --database-version=MYSQL_5_7 \
    --gce-zone=$ZONE \
    --tier=$TIER

RET=1
while [ $RET -ne 0 ]; do
    gcloud sql instances list | grep $NAME > /dev/null 2>&1
    RET=$?
    if [ $RET -ne 0 ]; then
        sleep 10
    fi
done

sleep 30

gcloud sql databases create tekapocart --instance=$NAME \
    --charset=utf8 \
    --collation=utf8_general_ci

gcloud sql users set-password root % --instance=$SERVICE_NAME_SQL --password=$DB_RT_PASSWD
gcloud sql users create tekapocart % --instance=$SERVICE_NAME_SQL --password=$DB_PASSWD
