#!/bin/sh

set -eux

TRIGGER=$1
ACTOR=$2
VPC="vpc-04848f977fbc9560d"

# Stop here in schedule
[ ! $TRIGGER = "maintenance" ] || exit 0

sleep 10

EC2_IP=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=[running]" "Name=tag:Name,Values='trustlist-ephemeral-$ACTOR-*'" "Name=network-interface.vpc-id,Values=[$VPC]" --query "Reservations[*].Instances[*].[NetworkInterfaces[*].[PrivateIpAddress]]" --output text)

echo "URL: http://$EC2_IP:4000"
