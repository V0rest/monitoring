
provider "aws" {
  region = "${var.region}"
#  shared_credentials_file = "~/.aws/credentials"
  profile = "default" # you may change to desired profile
}

#Create role
resource "aws_iam_role" "role" {
  name = "ssm-ec2-monitoring"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#attach policy to role
resource "aws_iam_role_policy_attachment" "attach" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
      ])
  role       = aws_iam_role.role.name
  policy_arn = each.value
}

#create profile for ec2
resource "aws_iam_instance_profile" "profile" {
  name  = "monitoring"
  role  = "ssm-ec2-monitoring"
}

#Create Security group
resource "aws_security_group" "monitoring-sg" {
  name        = "${var.instanceName}"
  description = "Allow monitoring"
  vpc_id      = "${var.vpc}" #data.aws_vpc.target_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.ingressCIDRblock}"
  }

  #allow ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #allow gafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow output
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.instanceName}"
    Environment = "${var.environment}"
    Region      = "${var.region}"
  }
}

#Create instance
resource "aws_instance" "Prometheus" {
  ami                         = data.aws_ami.os.id
  associate_public_ip_address = true
  subnet_id                   = "${var.subnet}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = [aws_security_group.monitoring-sg.id]
  iam_instance_profile        = "monitoring"


#volume size
  ebs_block_device {
     device_name = "/dev/xvda"
     volume_type = "${var.volume_type}"
     volume_size = "${var.volume_size}"
     delete_on_termination = false
   }
  tags = {
    Name        = "${var.instanceName}"
    Environment = "${var.environment}"
    Region      = "${var.region}"
    OS          = "${var.OStype}"
  }
}

#Create S3 bucket
#resource "aws_s3_bucket" "b" {
#  bucket = "monitoring-prometheus-grafana"
#  acl    = "private"
#
#  tags = {
#    Name        = "${var.instanceName}-${var.region}"
#    Environment = "${var.environment}"
#    Region      = "${var.region}"
#  }
#}



terraform {
  backend "s3" {
    bucket         = "office-monitoring" # Replace this with your bucket name!
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "office-monitoring" # Replace this with your DynamoDB table name!
    encrypt        = true
    shared_credentials_file = "~/.aws/credentials"
  }
}
