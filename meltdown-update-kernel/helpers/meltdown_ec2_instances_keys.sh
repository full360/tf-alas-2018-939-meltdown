#!/bin/bash
# Input directory where the keys are (cwd where terraform apply is run)
# Options
#  -p gets instance to private ips mapping
#  -k gets instance to private ssh keys (found in the local keys dir)
#  <path to keys>
#  <filter to use>

# grab the list of keys here
keys=`ls -m $2/keys |tr -d ' '`

# find all the instances that use the keys and are running
json=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=key-name,Values=$keys"  $3`


while getopts ":k:p:" opt; do
  case $opt in
    k) echo "$json"   | jq -r '[ .Reservations[] |  .Instances[] |  {(.InstanceId): (.KeyName)} ] | unique | add'
    ;;
    p) echo "$json"   | jq -r '[ .Reservations[] |  .Instances[] |  {(.InstanceId): (.PrivateIpAddress)} ] | unique | add'
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done
