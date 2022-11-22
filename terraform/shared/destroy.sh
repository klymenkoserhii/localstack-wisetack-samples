source ../shared/get-profile.sh

terraform destroy -var="profile=$PROFILE" -input=false -auto-approve
