#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0c30101d8120551f5"
ZONE_ID="Z04194951UBY03IZ86RXM"
DOMAIN_NAME="hkdevops.site"
INSTANCES=(mongodb mysql redis rabbitmq catalog user cart shipping payment dispatch frontend)

SETUP_HOSTED_ZONE(){
    aws route53 change-resource-record-sets --hosted-zone-id $3 --change-batch "
    {
        "Comment": "Creating hosted zones",
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "$2.$4",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                        {
                            "Value": $1
                        }
                    ]
                }
            }
        ]
    }"
}


for i in "${INSTANCES[@]}" ; do
    instanceID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query "Instances[0].InstanceId" --output text)
    if [ $i != "frontend" ] ; then
        IP=$(aws ec2 describe-instances --instance-ids $instanceID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $instanceID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
    echo "$i IP Address : $IP"

    SETUP_HOSTED_ZONE $IP $i $ZONE_ID $DOMAIN_NAME

done

