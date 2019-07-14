#!/bin/sh

while getopts d: option
    do
    case "${option}"
    in
        d) DOMAIN=${OPTARG};;
    esac
done

if [ -z "$DOMAIN" ]; then
    echo "請輸入商店網址 例如：www.yoursite.com"
    exit 1;
fi

REGION=asia-east1
NAME=$(echo $DOMAIN-ip | tr . -)

CHECK_IP=$(gcloud compute addresses list | grep $NAME)
if [ ${#CHECK_IP} -eq 0 ]; then	
    gcloud compute addresses create $NAME --region=$REGION
	CHECK_IP=$(gcloud compute addresses list | grep $NAME)
fi

VM_IP=$(echo $CHECK_IP | awk '{print $2;}')
echo $VM_IP
