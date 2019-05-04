#!/bin/sh

PROJECT_ID=shop-yoursite-com

CHECK_PID=$(gcloud projects list | grep $PROJECT_ID)
if [ ${#CHECK_PID} -eq 0 ]; then
	echo 'no project permission'
	exit
fi

gcloud config set project $PROJECT_ID
