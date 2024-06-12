#!/bin/bash

# AMI ID, Security Group ID, Zone ID, and Domain Name
AMI="ami-031d574cddc5bb371" # This should be dynamically updated if it changes often
SG_ID="sg-0918fbe51ab2db638" # Replace with your Security Group ID
ZONE_ID="Z02400681RG5QICC3BHZN" # Replace with your Route 53 Zone ID
DOMAIN_NAME="bigmatrix.in"

# Array of instance names
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")

# Loop through each instance name
for i in "${INSTANCES[@]}"
do
    # Determine instance type based on instance name
    if [ "$i" == "mongodb" ] || [ "$i" == "mysql" ] || [ "$i" == "shipping" ]; then
        INSTANCE_TYPE="t3.small"
    else
        INSTANCE_TYPE="t2.micro"
    fi

    # Launch the EC2 instance and capture its private IP address
    IP_ADDRESS=$(aws ec2 run-instances \
        --image-id "$AMI" \
        --instance-type "$INSTANCE_TYPE" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" \
        --query 'Instances[0].PrivateIpAddress' \
        --output text \
        --no-cli-pager)
    
    # Check if the IP_ADDRESS variable is empty, which indicates a failure in instance creation
    if [ -z "$IP_ADDRESS" ]; then
        echo "Failed to launch instance for $i. Skipping DNS record creation."
        continue
    fi

    # Output the instance name and its IP address
    echo "$i: $IP_ADDRESS"

    # Create or update Route 53 DNS record
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "$(cat <<EOF
{
    "Comment": "Creating or updating a record set for $i.$DOMAIN_NAME",
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$i.$DOMAIN_NAME",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [{"Value": "$IP_ADDRESS"}]
        }
    }]
}
EOF
)"
done
