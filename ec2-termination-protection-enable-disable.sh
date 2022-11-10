#########
# Enable
#########
#!/bin/bash
# Enable termination protection

set -x
# Purpose: To protect all my existing resources from accidental termination

REGION="us-east-1"
INSTANCE_ID=$(aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].InstanceId' --region $REGION)

export REGION
export INSTANCE_ID

for ec2 in $INSTANCE_ID
do
  echo "protecting ec2 in region $REGION"
  aws ec2 modify-instance-attribute --disable-api-termination --instance-id $ec2
done

#########
# Disable
#########
------------------------------------------------------------------------------------------------------------------------------------------

#!/bin/bash
# Disable termination protection

set -x
# Purpose: To protect all my existing resources from accidental termination

REGION="us-east-1"
INSTANCE_ID=$(aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].InstanceId' --region $REGION)

export REGION
export INSTANCE_ID

for ec2 in $INSTANCE_ID
do
  echo "protecting ec2 in region $REGION"
  aws ec2 modify-instance-attribute --no-disable-api-termination --instance-id $ec2
done










# Useful links

# http://pinter.org/archives/7886
# https://www.reddit.com/r/aws/comments/56hh4b/learning_aws_cli_how_can_i_get_a_list_of_instance/
# https://gist.github.com/Huevos-y-Bacon/54c80333d73449bbffbf8e595e03e30c

# Loop through all EC2 instances and enable termination protection
#for I in $(aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId]' --output text); do aws ec2 modify-instance-attribute --disable-api-termination --instance-id $I; done
#
## Loop through all EC2 instances and disable termination protection
#for I in $(aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId]' --output text); do aws ec2 modify-instance-attribute --no-disable-api-termination --instance-id $I;done


#End
