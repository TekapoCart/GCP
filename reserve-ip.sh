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
    *)
        shift
        ;;
    esac
    shift
done

REGION=asia-east1
NAME=$(echo $DOMAIN-ip | tr . -)
gcloud compute addresses create $NAME --region=$REGION
