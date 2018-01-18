#!/bin/bash
function update_kernel_tag() {
  kernel=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./access_key/private_key ec2-user@$2 'uname -or')
  # jq -n --arg i "i-0006318cde6e2fc36" --arg k "4.9.75-25.55.amzn1.x86_64 GNU/Linux" --argjson r "{ \"kernels\" : [] }" '$r | .kernels += [{ "\($i)":$k }] '
  # echo $result | jq -n --arg i "$3" --arg k "$kernel" '.kernels += [{ "\($i)":$k }] '
  # echo $result | jq -r --arg i "$3" --arg k "$kernel" '.kernels += [ {"key":$i, "value":$k} ]' > kernels.json
  cat kernels.json
  # cat kernels.json | jq --arg i "$3" --arg k "$kernel" '.kernels += [ {"key":$i, "value":$k} ]'
  result=`cat kernels.json | jq --arg i "$3" --arg k "$kernel" '.kernels += [ {"\($i)":$k} ] '`
  echo $result > kernels.json
}
# jq -n '"{ \"kernels\" : [] }"' > kernels.json
# json=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"`
echo "{ \"kernels\" : [] }" | jq . > kernels.json
resources=` cat instances.json | jq -r '[[ .Reservations[] |  .Instances[] |  {(.InstanceId): (.PrivateIpAddress)} ] | unique | add | to_entries | .[] | "\(.key)|\(.value)" ] | join(" ")'`
for i in $resources; do
  instance=`echo $i | cut -d '|' -f1`
  ip=`echo $i | cut -d '|' -f2`
  # echo $1 $ip $instance $result
  update_kernel_tag $1 $ip $instance
done
rm kernels.json
