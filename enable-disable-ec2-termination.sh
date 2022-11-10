##################################################################################################
# Loop through all EC2 instances (excluding terminated and spot) and enable termination protection
##################################################################################################

for I in $(aws ec2 describe-instances --query \
  'Reservations[].Instances[?(InstanceLifecycle!=`spot` && InstanceState!=terminated)].[InstanceId]' \
  --output text); do
  aws ec2 modify-instance-attribute --disable-api-termination --instance-id $I;
done




#################################################################################################
# Loop through all EC2 instances (excluding terminated and spot) and disable termination protection
#################################################################################################

for I in $(aws ec2 describe-instances --query \
  'Reservations[].Instances[?(InstanceLifecycle!=`spot` && InstanceState!=terminated)].[InstanceId]' \
  --output text); do
  aws ec2 modify-instance-attribute --no-disable-api-termination --instance-id $I;
done
