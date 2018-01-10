data "external" "get_instance_private_key_map" {
  program = [
    "bash",
    "${path.module}/helpers/meltdown_ec2_instances.sh",
    "-k",
    "${path.cwd}",
    "${var.filter}"
  ]
}

data "external" "get_instance_private_ip_map" {
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
}

resource "null_resource" "meltdown_patch" {
  count = "${length(local.instances)}"

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y kernel kernel-tools perf",
      "sleep 20",
      "sudo reboot"
    ]
    connection {
      host = "${lookup(local.instance_private_ips, local.instances[count.index])}"
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${path.cwd}/keys/${lookup(local.instance_private_keys, local.instances[count.index])}")}"
    }
  }
}
