#!/bin/sh

while getopts d: option
    do
    case "${option}"
    in
        d) DOMAIN=${OPTARG};;
    esac
done

if [ -z "$DOMAIN" ]; then
    echo "請輸入商店網址"
    exit 1;
fi

REGION=asia-east1
NAME=$(echo $DOMAIN-ip | tr . -)
gcloud compute addresses create $NAME --region=$REGION
