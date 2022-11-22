#!/bin/bash
source ../shared/get-profile.sh
terraform apply -var="profile=$PROFILE" -input=false -auto-approve
