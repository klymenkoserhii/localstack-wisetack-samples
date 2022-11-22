#!/bin/bash
source ../sared/get-profile.sh
terraform apply -var="profile=$PROFILE" -input=false -auto-approve
