#!/bin/bash
# Input directory where the keys are (cwd where terraform apply is run)

# grab the list of keys here
keys=`ls -m $1/keys |tr -d ' '`

# find all the instances that use the keys and are running
json=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=key-name,Values=$keys"`

# parse the json to generate a map of ami_id : private_key
echo "$json"  | jq -r '[ .Reservations[] | .Instances[] |  {(.ImageId): (.KeyName)} ] | unique | add  '
