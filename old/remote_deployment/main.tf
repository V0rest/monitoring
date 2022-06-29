
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
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
resource "aws_security_group" "Monitoring-sg" {
  name        = "${var.instanceName}"
  description = "Allow tcp 22,9090,3000,9093,9100,8080"
#vpc_id      = data.aws_vpc.target_vpc.id

#allow ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.ingressCIDRblock}"
  }
  #allow prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = "${var.ingressCIDRblock}"
  }
  #allow gafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = "${var.ingressCIDRblock}"
  }
  #allow alertmanager
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = "${var.ingressCIDRblock}"
  }
  #allow node-exporter
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = "${var.ingressCIDRblock}"
  }
  #allow cadvisor
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = "${var.ingressCIDRblock}"
  }
  #allow output
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.egressCIDRblock}"
  }
  tags = {
    Name        = "${var.instanceName}"
    Environment = "${var.environment}"
    Region      = "${var.region}"
  }
}

#Create instance
resource "aws_instance" "Monitoring" {
  ami                         = data.aws_ami.os.id
  associate_public_ip_address = true
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = [aws_security_group.Monitoring-sg.id]
  iam_instance_profile        = "monitoring"
  # Install docker
  user_data                   = file("bootstrap.sh")

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
resource "aws_s3_bucket" "b" {
  bucket = "vitech-monitoring"
  acl    = "private"

  tags = {
    Name        = "${var.instanceName}-${var.region}"
    Environment = "${var.environment}"
    Region      = "${var.region}"
  }
}
