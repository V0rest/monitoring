  variable "access_key" {
       default = ""
  }

  variable "secret_key" {
       default = ""
  }

  variable "region" {
       default = "us-east-1"
  }

  variable "volume_size" {
    default = "20"
  }

  variable "volume_type" {
    default = "gp2"
  }

  variable "instanceName" {
    default = "Prometheus-Grafana"
  }

  variable "environment" {
    default = "Prod"
  }

  variable "OStype" {
    default = "AWS-Linux-2"
  }

  variable "key_name" {
    default = "prometheus"
  }

  variable "instance_type" {
    default = "t2.micro"
  }

  variable "ingressCIDRblock" {
      type = list
      default = [ "94.153.146.34/32" , "91.225.200.152/32" , "178.136.126.146/32"]
  }

  variable "egressCIDRblock" {
      type = list
      default = [ "0.0.0.0/0" ]
  }

  variable "ami" {
          default = ["amzn2-ami-hvm*"]
      }
#  variable "ami" {
#          default = ["*ubuntu-focal-20.*-amd64-server-*"]
#      }

  variable "ami_owner" {
  default = "amazon"
}


#  variable "ami_owner" {
#  default = "099720109477"
#}
