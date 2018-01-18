data "external" "get_instance_private_key_map" {
  program = [
    "bash",
    "${path.module}/helpers/meltdown_ec2_instances_keys.sh",
    "-k",
    "${path.cwd}",
    "${var.filter}"
  ]
}

data "external" "get_instance_private_ip_map" {
  program = [
    "bash",
    "${path.module}/helpers/meltdown_ec2_instances_keys.sh",
    "-p",
    "${path.cwd}",
    "${var.filter}"
  ]
}

data "external" "get_running_instance_private_key_map" {
  program = [
    "bash",
    "${path.module}/helpers/meltdown_ec2_instances.sh",
    "-k",
    "${path.cwd}",
    "${var.filter}"
  ]
}

data "external" "get_running_instance_private_ip_map" {
  program = [
    "bash",
    "${path.module}/helpers/meltdown_ec2_instances.sh",
    "-p",
    "${path.cwd}",
    "${var.filter}"
  ]
}

locals {
  instance_private_ips = "${data.external.get_instance_private_ip_map.result}"
  instance_private_keys = "${data.external.get_instance_private_key_map.result}"
  instances = "${keys(local.instance_private_keys)}"
  running_instance_private_ips = "${data.external.get_running_instance_private_ip_map.result}"
  running_instance_private_keys = "${data.external.get_running_instance_private_key_map.result}"
  running_instances = "${keys(local.running_instance_private_keys)}"
  ssh_key = "${substr(file("${path.cwd}/access_key/public_key"),0,length(file("${path.cwd}/access_key/public_key"))-1)}"
  remove_key_command = "if test -f $HOME/.ssh/authorized_keys; then if grep -v '${local.ssh_key}' $HOME/.ssh/authorized_keys > $HOME/.ssh/tmp; then cat $HOME/.ssh/tmp > $HOME/.ssh/authorized_keys && rm $HOME/.ssh/tmp; else rm $HOME/.ssh/tmp; fi; fi",
  add_key_command = "echo '${local.ssh_key}' >> .ssh/authorized_keys"

}

resource "null_resource" "meltdown_ssh_key_add" {
  count = "${ var.enable_add_key ? length(local.instances) : 0 }"

  provisioner "remote-exec" {
    inline = [
      "${local.remove_key_command}",
      "${local.add_key_command}",

    ]
    connection {
      host = "${lookup(local.instance_private_ips, local.instances[count.index])}"
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${path.cwd}/keys/${lookup(local.instance_private_keys, local.instances[count.index])}")}"
    }
  }
}

resource "null_resource" "meltdown_ssh_key_remove" {
  count = "${ var.enable_remove_key ? length(local.instances) : 0 }"

  provisioner "remote-exec" {
    inline = [
      "${local.remove_key_command}"
    ]
    connection {
      host = "${lookup(local.instance_private_ips, local.instances[count.index])}"
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${path.cwd}/keys/${lookup(local.instance_private_keys, local.instances[count.index])}")}"
    }
  }
}

resource "null_resource" "meltdown_patch" {
  count = "${ var.enable_patch_meltdown ? length(local.running_instances) : 0 }"

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y kernel kernel-tools perf",
      "sleep 20",
      "sudo reboot"
    ]
    connection {
      host = "${lookup(local.running_instance_private_ips, local.running_instances[count.index])}"
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${path.cwd}/access_key/private_key")}"
    }
  }
}

output running_ip_list {
  value = "${local.running_instance_private_ips}"
}

output running_key_list {
  value = "${local.running_instance_private_keys}"
}
