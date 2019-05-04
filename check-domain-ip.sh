#!/bin/sh

DOMAIN=shop.yoursite.com

DOMAIN_IP=$(ping -c 1 $DOMAIN | gawk -F'[()]' '/PING/{print $2}')
VM_IP=$(gcloud compute addresses list | grep $NAME | awk '{print $3;}')
if [$DOMAIN_IP != $VM_IP]; then
	echo "網域 IP 不正確"
	exit
fi
