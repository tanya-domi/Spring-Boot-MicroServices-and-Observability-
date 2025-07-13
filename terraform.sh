#!/usr/bin/env bash

export TF_LOG="DEBUG"
export TF_LOG_PATH="./terraform.log"

ENV=prod
TF_PLAN="${ENV}".tf_plan

#2. Install tfsec
# if [ -f /usr/local/bin/tfsec ]
# then
#   echo "tfsec is already installed"
#   else
# wget https://github.com/tfsec/tfsec/releases/latest/download/tfsec-linux-amd64
# chmod +x tfsec-linux-amd64
# sudo mv tfsec-linux-amd64 /usr/local/bin/tfsec
# fi
 

#3.RM .terraform directory
[ -d .terraform ] && rm -rf .terraform
rm -f *.tf_plan
sleep 2

#4. plan
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=${TF_PLAN}


#5. checkov
terraform show -json "$TF_PLAN" | jq '.' > "${TF_PLAN}.json"  # # checkov reads file in JSON format
checkov -f "${TF_PLAN}.json"