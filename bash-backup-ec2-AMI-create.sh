1. packages awscli

apt update -y && apt install -y awscli jq

2. cron setup, job run after every 1 hour

crontab -e (Hourly)
0 * * * * chmod 700 /root/backup.sh && /root/backup.sh

(Every 15 minutes)
*/15 * * * * chmod 700 /root/backup.sh && /root/backup.sh

crontab -l

cron logs
grep CRON /var/log/syslog

3. policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AMIAndInstancePermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeTags",
        "ec2:CreateImage",
        "ec2:DeregisterImage",
        "ec2:CreateTags",
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*"
    }
  ]
}

4. service

#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Update the package list
apt update

# Install Apache2
apt install -y apache2

# Enable Apache2 to start on boot
systemctl enable apache2

# Start Apache2
systemctl start apache2

# Print the status of Apache2
systemctl status apache2

# Print the message
echo "Apache installation is complete."

#End





5.
#!/usr/bin/env bash

set -xe

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# AWS Region variable
REGION='us-east-1'

# Retention period for AMIs
RETENTION_PERIOD=3

# Function to exit with an error message
function die {
  echo "Error: $1"
  exit 1
}

# Step 1: Stop the apache2.service
echo "Stopping apache2.service..."
sudo systemctl stop apache2.service || die "Failed to stop apache2.service"

# Step 2: Create an AMI of the current EC2 instance

# Get the instance ID of the running EC2 instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
[[ -z "$INSTANCE_ID" ]] && die "Failed to get instance ID"

# Get the Name tag of the EC2 instance
INSTANCE_NAME=$(aws ec2 describe-tags \
  --region "$REGION" \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
  --query 'Tags[0].Value' \
  --output text) || die "Failed to get instance Name"
[[ -z "$INSTANCE_NAME" ]] && die "Instance Name is empty"

# Generate a unique name for the AMI based on the Name tag
AMI_NAME="$INSTANCE_NAME-ami-$(date +'%Y-%m-%d-%H-%M-%S')"

echo "Creating AMI named $AMI_NAME from instance $INSTANCE_ID..."

# Create the AMI and get the AMI ID
AMI_ID=$(aws ec2 create-image \
  --region "$REGION" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --description "An AMI for apache2.service" \
  --no-reboot \
  --query 'ImageId' \
  --output text) || die "Failed to create AMI"
[[ -z "$AMI_ID" ]] && die "AMI ID is empty"

echo "AMI creation started. AMI ID is $AMI_ID."

# Tag the AMI with the Name of the instance
aws ec2 create-tags \
  --region "$REGION" \
  --resources "$AMI_ID" \
  --tags "Key=Name,Value=$INSTANCE_NAME" || die "Failed to tag AMI"

# Step 3: Verify AMI creation

echo "Verifying AMI creation..."
while true; do
  AMI_STATE=$(aws ec2 describe-images \
    --region "$REGION" \
    --image-ids "$AMI_ID" \
    --query 'Images[0].State' \
    --output text) || die "Failed to fetch AMI state"

  if [[ "$AMI_STATE" == "available" ]]; then
    echo "AMI is available."
    break
  elif [[ "$AMI_STATE" == "pending" ]]; then
    echo "AMI is still pending. Waiting..."
    sleep 10
  else
    die "AMI is in an unexpected state: $AMI_STATE"
  fi
done

# Step 4: Remove old backups, retain last $RETENTION_PERIOD

echo "Removing old backups, retaining last $RETENTION_PERIOD..."
OLD_AMIS=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners "self" \
  --filters "Name=name,Values=$INSTANCE_NAME-ami-*" \
  --query "Images | sort_by(@, &CreationDate)" \
  --output json) || die "Failed to list old AMIs"

# Filter out the latest N AMIs, delete the rest
TOTAL_AMIS=$(echo "$OLD_AMIS" | jq '. | length')
AMIS_TO_DELETE=$(echo "$OLD_AMIS" | jq ".[0:$(($TOTAL_AMIS - $RETENTION_PERIOD))]")

for OLD_AMI in $(echo "$AMIS_TO_DELETE" | jq -r '.[].ImageId'); do
  echo "Deregistering old AMI $OLD_AMI..."
  aws ec2 deregister-image \
    --region "$REGION" \
    --image-id "$OLD_AMI" || die "Failed to deregister $OLD_AMI"

  # Get the snapshot ID associated with the AMI
  SNAPSHOT_ID=$(echo "$AMIS_TO_DELETE" | jq -r --arg OLD_AMI "$OLD_AMI" '.[] | select(.ImageId == $OLD_AMI) | .BlockDeviceMappings[0].Ebs.SnapshotId')

  # Delete the snapshot
  echo "Deleting snapshot $SNAPSHOT_ID..."
  aws ec2 delete-snapshot \
    --region "$REGION" \
    --snapshot-id "$SNAPSHOT_ID" || die "Failed to delete snapshot $SNAPSHOT_ID"
done

# Step 5: Start the apache2.service again

echo "Starting apache2.service..."
sudo systemctl start apache2.service || die "Failed to start apache2.service"

echo "Script completed successfully."

# End


# Version2 Backups

#!/usr/bin/env bash

set -xe

# Validate superuser privileges
if [ "$(id -u)" -ne 0 ]; then
    log_this "Error: This script requires superuser privileges."
    exit 1
fi

# Function to log messages
log_this() {
    echo "$1"
}

# Function to exit with an error message
die() {
  echo "Error: $1"
  exit 1
}

# Function to stop services
stop_service() {
    local service_name="$1"
    log_this "Stopping ${service_name}"
    systemctl stop "$service_name" || {
        log_this "Error: Failed to stop ${service_name}"
        exit 1
    }
    sleep 2 # Allow time for service to stop
}

# Function to start services
start_service() {
    local service_name="$1"
    log_this "Starting ${service_name}"
    systemctl start "$service_name" || {
        log_this "Error: Failed to start ${service_name}"
        exit 1
    }
}

# AWS Region variable
REGION='us-east-1'

# Retention period for AMIs
RETENTION_PERIOD=3

# Step 1: Stop the apache2.service
stop_service "apache2.service"

# Step 2: Create an AMI of the current EC2 instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
[[ -z "$INSTANCE_ID" ]] && die "Failed to get instance ID"

INSTANCE_NAME=$(aws ec2 describe-tags \
  --region "$REGION" \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
  --query 'Tags[0].Value' \
  --output text) || die "Failed to get instance Name"

[[ -z "$INSTANCE_NAME" ]] && die "Instance Name is empty"

AMI_NAME="$INSTANCE_NAME-ami-$(date +'%Y-%m-%d-%H-%M-%S')"

AMI_ID=$(aws ec2 create-image \
  --region "$REGION" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --description "An AMI for apache2.service" \
  --no-reboot \
  --query 'ImageId' \
  --output text) || die "Failed to create AMI"

[[ -z "$AMI_ID" ]] && die "AMI ID is empty"

log_this "AMI creation started. AMI ID is $AMI_ID."

aws ec2 create-tags \
  --region "$REGION" \
  --resources "$AMI_ID" \
  --tags "Key=Name,Value=$INSTANCE_NAME" || die "Failed to tag AMI"

# Step 3: Verify AMI creation
while true; do
  AMI_STATE=$(aws ec2 describe-images \
    --region "$REGION" \
    --image-ids "$AMI_ID" \
    --query 'Images[0].State' \
    --output text) || die "Failed to fetch AMI state"

  if [[ "$AMI_STATE" == "available" ]]; then
    log_this "AMI is available."
    break
  elif [[ "$AMI_STATE" == "pending" ]]; then
    log_this "AMI is still pending. Waiting..."
    sleep 10
  else
    die "AMI is in an unexpected state: $AMI_STATE"
  fi
done

# Step 4: Start the apache2.service again
start_service "apache2.service"

log_this "Script completed successfully."

# Step 5: Remove old backups, retain last $RETENTION_PERIOD

echo "Removing old backups, retaining last $RETENTION_PERIOD..."
OLD_AMIS=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners "self" \
  --filters "Name=name,Values=$INSTANCE_NAME-ami-*" \
  --query "Images | sort_by(@, &CreationDate)" \
  --output json) || die "Failed to list old AMIs"

# Filter out the latest N AMIs, delete the rest
TOTAL_AMIS=$(echo "$OLD_AMIS" | jq '. | length')
AMIS_TO_DELETE=$(echo "$OLD_AMIS" | jq ".[0:$(($TOTAL_AMIS - $RETENTION_PERIOD))]")

for OLD_AMI in $(echo "$AMIS_TO_DELETE" | jq -r '.[].ImageId'); do
  echo "Deregistering old AMI $OLD_AMI..."
  aws ec2 deregister-image \
    --region "$REGION" \
    --image-id "$OLD_AMI" || die "Failed to deregister $OLD_AMI"

  # Get the snapshot ID associated with the AMI
  SNAPSHOT_ID=$(echo "$AMIS_TO_DELETE" | jq -r --arg OLD_AMI "$OLD_AMI" '.[] | select(.ImageId == $OLD_AMI) | .BlockDeviceMappings[0].Ebs.SnapshotId')

  # Delete the snapshot
  echo "Deleting snapshot $SNAPSHOT_ID..."
  aws ec2 delete-snapshot \
    --region "$REGION" \
    --snapshot-id "$SNAPSHOT_ID" || die "Failed to delete snapshot $SNAPSHOT_ID"
done

# End

