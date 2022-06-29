#variable "access_key" {
#     default = ""
#}

#variable "secret_key" {
#     default = ""
#}

variable "region" {
     default = "eu-west-1"
}

variable "volume_size" {
  default = "30"
}

variable "volume_type" {
  default = "gp2"
}

variable "instanceName" {
  default = "Monioring-Prometheus-Grafana"
}

variable "environment" {
  default = "Prod"
}

variable "OStype" {
  default = "AWS-Linux-2"
}

variable "key_name" {
  default = "monitoring"
}

variable "instance_type" {
  default = "t2.small"
}

variable "ingressCIDRblock" {
  type = list
  default = ["94.153.146.34/32", "178.136.126.146/32", "172.31.0.0/24", "172.27.0.0/16", "192.168.0.0/16", "91.225.200.152/32"]
}

variable "egressCIDRblock" {
  type = list
  default = [ "0.0.0.0/0" ]
}

variable "ami" {
  default = ["amzn2-ami-hvm*"]
}

variable "ami_owner" {
  default = "amazon"
}

variable "vpc" {
  default = "vpc-01f7ecba37b5211d1"
}


variable "subnet" {
  default = "subnet-0f37c5e68a6ccb611"
}
