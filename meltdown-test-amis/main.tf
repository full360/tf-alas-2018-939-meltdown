data "external" "get_ami_private_key_map" {
  program = [
    "bash",
    "${path.module}/helpers/get_ami_private_key_map.sh",
    "${path.cwd}"
  ]
}

locals {
  private_keys = "${data.external.get_ami_private_key_map.result}"
  amis = "${keys(local.private_keys)}"
}

resource "aws_instance" "meltdown_test" {
  count = "${length(local.amis)}"
  ami = "${local.amis[count.index]}"
  instance_type = "${var.intance_type}"
  availability_zone = "${var.availability_zone}"
  vpc_security_group_ids = "${var.vpc_security_group_ids}"
  subnet_id = "${var.subnet_id}"
  key_name = "${lookup(local.private_keys, local.amis[count.index])}"
  tags {
    Name = "alas-2018-939-${local.amis[count.index]}"
    MeltdownTest = "true"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y kernel kernel-tools perf",
      "sleep 20",
      "sudo reboot"
    ]
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("keys/${lookup(local.private_keys, local.amis[count.index])}")}"
    }
  }
}

# Debug
# output "get_ami_private_key_map" {
#   value = "${lookup(local.private_keys,local.amis[0])}"
# }
