#!/bin/bash

#Check if jq is installed and if not install it and restart the script
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  echo 'Installing jq...'
  sudo apt-get install jq
  source deploy.sh
fi
#Check if pv is installed and if not install it and restart the script
if ! [ -x "$(command -v pv)" ]; then
  echo 'Error: pv is not installed.' >&2
  echo 'Installing pv...'
  sudo apt-get install pv
  source deploy.sh
fi
# Making it easy to use colors in output
RESET="\033[0m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
WHITE="\033[0;37m"

# Splash Screen. This needs to be WAY better lol
wget -q -O- "http://artscene.textfiles.com/vt100/moon.animation" |pv -q -L 3600
echo ""
echo -e "$RED ========= AWS Automation Project =========$RESET"
echo ""

# List existing profiles

existing_profiles=$(grep '\[.*\]' ~/.aws/credentials | sed 's/\[//' | sed 's/\]//')
echo -e "$YELLOW Select an existing AWS profile by entering the corresponding number or enter a new name to create a new profile: "
echo -e "$existing_profiles" | nl -v 0

read -p " Enter the number or a new name of the profile you want to use: " profile_choice
echo -e "$RESET"
if [[ $profile_choice =~ ^[0-9]+$ ]]; then
    profile_name=$(echo -e "$existing_profiles" | sed -n "${profile_choice}p")
else
    profile_name=$profile_choice
    read -p "Enter your AWS access key: " access_key
    read -p "Enter your AWS secret key: " secret_key
    read -p "Enter your AWS session token: " session_token
    read -p "Enter the region you want to launch the instance in: " region
    aws configure set aws_access_key_id $access_key --profile $profile_name
    aws configure set aws_secret_access_key $secret_key --profile $profile_name
    aws configure set aws_session_token $session_token --profile $profile_name
    aws configure set region $region --profile $profile_name
fi

# set selected or created profile to be used globally in script
export AWS_PROFILE=$profile_name

# Enter your VPC ID

vpc_list=$(aws ec2 describe-vpcs --query 'Vpcs[*].{ID:VpcId,Name:Tags[?Key==`Name`]|[0].Value}' --output json)

echo "Select the VPC you want to use by entering the corresponding number:"
echo "$vpc_list" | jq -r '.[] | "\(.Name) \(.ID)"' | nl -v 0

read -p "Enter the number corresponding to the VPC you want to use: " vpc_choice
vpc_id=$(echo "$vpc_list" | jq -r ".[$vpc_choice].ID")


# Enter your Subnet ID
subnet_list=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].{ID:SubnetId,Name:Tags[?Key==`Name`]|[0].Value,AvailabilityZone:AvailabilityZone}' --output json)

echo "Select the subnet you want to use by entering the corresponding number:"
echo "$subnet_list" | jq -r '.[] | "\(.Name) \(.ID) \(.AvailabilityZone)"' | nl -v 0

read -p "Enter the number corresponding to the subnet you want to use: " subnet_choice
subnet_id=$(echo "$subnet_list" | jq -r ".[$subnet_choice].ID")

sub_id=$subnet_id

#Enter your route table ID - Optional
route_table_list=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[*].{ID:RouteTableId,Name:Tags[?Key==`Name`].Value[]}' --output json)

echo "Select the route table you want to use by entering the corresponding number:"
echo "$route_table_list" | jq -r '.[] | "\(.Name) \(.ID)"' | nl -v 0

read -p "Enter the number corresponding to the route table you want to use: " route_table_choice
route_table_id=$(echo "$route_table_list" | jq -r ".[$route_table_choice].ID")

#Enter internet gateway - Optional

igw_list=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[*].{ID:InternetGatewayId,Name:Tags[?Key==`Name`]|[0].Value}' --output json)

echo "Select the internet gateway you want to use by entering the corresponding number:"
echo "$igw_list" | jq -r '.[] | "\(.Name) \(.ID)"' | nl -v 0

read -p "Enter the number corresponding to the internet gateway you want to use: " igw_choice
igw_id=$(echo "$igw_list" | jq -r ".[$igw_choice].ID")

# New create a custom sec group

sec_list=$(aws ec2 describe-security-groups --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName}' --output json)
echo "Select the security group you want to use by entering the corresponding number:"
echo "$sec_list" | jq -r '.[] | "\(.Name) \(.ID)"' | nl -v 0
read -p "Enter the number corresponding to the security group you want to use, or 0 to create a new one: " sec_choice
if [ $sec_choice -eq 0 ]
then
  read -p "Enter a name for the security group: " group_name
  read -p "Enter the IP address to allow SSH access from: " ip_address

  response=$(aws ec2 create-security-group --group-name $group_name --description "Security group for SSH access")
  sec_id=$(echo "$response" | jq -r '.GroupId')
  aws ec2 authorize-security-group-ingress --group-id $sec_id --protocol tcp --port 22 --cidr $ip_address/32
else
  sec_id=$(echo "$sec_list" | jq -r ".[$((sec_choice-1))].ID")
fi
#aws ec2 authorize-security-group-egress --group-id $sec_id --protocol -1 --port -1 --cidr 0.0.0.0/0

# Find the Kali Image AMI in your region

ami_list=$(aws ec2 describe-images --filters "Name=name,Values=kali-rolling-amd64*" "Name=owner-alias,Values=aws-marketplace" --query 'Images[*].{ID:ImageId,Name:Name}' --output json)

echo "Select the Kali Linux AMI you want to use by entering the corresponding number:"
echo "$ami_list" | jq -r '.[] | "\(.Name) \(.ID)"' | nl -v 0
read -p "Enter the number corresponding to the Kali Linux AMI you want to use: " kali_ami
aws_image_id=$(echo "$ami_list" | jq -r ".[$((kali_ami-1))].ID")


#Set the type of instance you would like. Here, I am specifying a T2 micro instance.
i_type="t2.medium"

# Create an optional tag.
read -p "Enter an optional tag for this job: " tag

# Generate a random id - This is optional for debugging and logging
#uid=$RANDOM

# Create AWS keypair with custom name and check if it already exists
read -p "Enter the name for an AWS key pair: " aws_key_name
ssh_key="$aws_key_name.pem"

if aws ec2 describe-key-pairs --key-name $aws_key_name &> /dev/null ; then
    echo "Key already exists, using existing key"
else
    echo "Generating key Pairs"
    aws ec2 create-key-pair --key-name $aws_key_name --query 'KeyMaterial' --output text 2>&1 | tee $ssh_key
    echo "Setting permissions"
    chmod 400 $ssh_key
fi

echo -e "$RED Creating EC2 instance in AWS$RESET"

ec2_id=$(aws ec2 run-instances --image-id $aws_image_id --count 1 --instance-type $i_type --key-name $aws_key_name --security-group-ids $sec_id --subnet-id $sub_id --associate-public-ip-address --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":30,"DeleteOnTermination":true}}]' --tag-specifications 'ResourceType=instance,Tags=[{Key=WatchTower,Value="$tag"},{Key=AutomatedID,Value="$uid"}]' | grep InstanceId | cut -d":" -f2 | cut -d'"' -f2)

# Log date, time, random ID
date >> logs.txt
#pwd >> logs.txt
echo $ec2_id >> logs.txt
echo ""
echo ""
echo "EC2 Instance ID: $ec2_id"
echo ""
echo ""
aws ec2 describe-instances --instance-ids $ec2_id --query 'Reservations[0].Instances[0].State.Name'

while [ $(aws ec2 describe-instances --instance-ids $ec2_id --query 'Reservations[0].Instances[0].State.Name' --output text) != "running" ]; do
  echo -e "$RED Waiting for instance to start...$RESET"
  sleep 1
done

public_dns=$(aws ec2 describe-instances --instance-ids $ec2_id --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/\"//g')


# Wait for SSH Service fix

spinner=("|" "/" "-" "\\")
echo""
echo "Waiting for SSH to start..."
for i in {1..90}
do
    printf "\r[%c] Loading... %d%%" ${spinner[i % 4]} $((i*100/90))
    sleep 1
done
aws ec2 describe-instances --instance-ids $ec2_id --query 'Reservations[0].Instances[0].PublicDnsName'

echo -e "SSH connect string for later if needed: ssh -i $ssh_key kali@$public_dns"

# connect to SSH

ssh -o "StrictHostKeyChecking no" -t -i "$ssh_key" kali@$public_dns 'bash -s' < commands.sh
