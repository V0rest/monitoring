#find last AMI
data "aws_ami" "os" {
  most_recent = true
  filter {
    name   = "name"
    values = "${var.ami}"
  }
    owners = ["${var.ami_owner}"]
}
