#!/bin/bash

<<<<<<< HEAD
AMI="ami-031d574cddc5bb371" # this keeps on changing
SG_ID="sg-0918fbe51ab2db638" # replace with your SG ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
ZONE_ID="Z02400681RG5QICC3BHZN" # replace your zone ID
=======
AMI="ami-0f3c7d07486cad139" # this keeps on changing
SG_ID="sg-0ecc0d38b1974ad3f" # replace with your SG ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
ZONE_ID="Z07107583SIBMEYCNYDA6" # replace your zone ID
>>>>>>> 0147ee2612a208a2ff7704a257cce32a7cf04460
DOMAIN_NAME="bigmatrix.in"

for i in "${INSTANCES[@]}"
do
    if [ "$i" == "mongodb" ] || [ "$i" == "mysql" ] || [ "$i" == "shipping" ]
    then
        INSTANCE_TYPE="t3.small"
    else
        INSTANCE_TYPE="t2.micro"
    fi

    IP_ADDRESS=$(aws ec2 run-instances --image-id "$AMI" --instance-type "$INSTANCE_TYPE" --security-group-ids "$SG_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PrivateIpAddress' --output text --no-cli-pager)
    echo "$i: $IP_ADDRESS"

    # Create R53 record, make sure you delete existing record
    aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "$(cat <<EOF
{
    "Comment": "Creating a record set for cognito endpoint",
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$i.$DOMAIN_NAME",
            "Type": "A",
<<<<<<< HEAD
            "TTL": 1,
=======
            "TTL": 300,
>>>>>>> 0147ee2612a208a2ff7704a257cce32a7cf04460
            "ResourceRecords": [{"Value": "$IP_ADDRESS"}]
        }
    }]
}
EOF
)"
done
