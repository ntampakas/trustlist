#!/bin/sh

set -eux

TRIGGER=$1
BRANCH=$2
ACTOR=$3
SHA=$4
AMI="ami-04e601abe3e1a910f"
SG="sg-0edb126b2d5fa18f7"
SUBNET="subnet-0fb41fbb99794e19b"
VPC="vpc-04848f977fbc9560d"

# Kill old instances
CURRENT_TIME_EPOCH=$(date -d `date -Is` +"%s")
EC2=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=[running]" "Name=tag:Name,Values='trustlist-ephemeral-*'" "Name=network-interface.vpc-id,Values=[$VPC]" --query "Reservations[*].Instances[*].InstanceId" --output text)
for i in $EC2; do
  EC2_LAUNCH_TIME=$(aws ec2 describe-instances --instance-ids $i --query 'Reservations[*].Instances[*].LaunchTime' --output text)
  LAUNCH_TIME_EPOCH=$(date -d $EC2_LAUNCH_TIME +"%s")
  diff=$(expr $CURRENT_TIME_EPOCH - $LAUNCH_TIME_EPOCH)

  if [ $diff -gt 43200 ]; then
    aws ec2 terminate-instances --instance-ids $i
  fi
done

# Stop here in schedule
[ ! $TRIGGER = "maintenance" ] || exit 0

# Check if actor ec2 exists
ACTOR_EC2=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=[running]" "Name=tag:Name,Values='trustlist-ephemeral-$ACTOR-*'" "Name=network-interface.vpc-id,Values=[$VPC]" --query "Reservations[*].Instances[*].InstanceId" --output text)

[ -z $ACTOR_EC2 ] || aws ec2 terminate-instances --instance-ids $ACTOR_EC2

# Launch new instance
aws ec2 run-instances \
  --user-data "file://.github/scripts/cloud-init.sh" \
  --image-id $AMI \
  --count 1 \
  --instance-type t3.xlarge \
  --key-name devops \
  --security-group-ids $SG \
  --subnet-id $SUBNET \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"DeleteOnTermination\":true}}]" \
  --instance-initiated-shutdown-behavior terminate \
  --tag-specification "ResourceType=instance,Tags=[{Key=Name,Value="trustlist-ephemeral-$ACTOR-$SHA"},{Key=Repo,Value="trustlist"},{Key=Branch,Value="$BRANCH"}]" \
  --metadata-options "InstanceMetadataTags=enabled"
