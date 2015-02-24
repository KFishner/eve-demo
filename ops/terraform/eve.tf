provider "aws" {
    access_key = "YOUR_KEY_HERE"
    secret_key = "YOUR_SECRET_HERE"
    region = "us-east-1"
}

resource "atlas_artifact" "eve" {
    name = "<username>/eve"
    type = "aws.ami"
}

resource "atlas_artifact" "mongo" {
    name = "<username>/mongo"
    type = "aws.ami"
}

resource "aws_security_group" "allow_all" {
  name = "allow_all"
    description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "eve" {
    instance_type = "t2.micro"
    ami = "${atlas_artifact.eve.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_all.name}"]

    # This will create 2 instances
    count = 2
    lifecycle = {
      create_before_destroy = true
    }
}

resource "aws_instance" "mongo" {
    instance_type = "t2.micro"
    ami = "${atlas_artifact.mongo.metadata_full.region-us-east-1}"
    security_groups = ["${aws_security_group.allow_all.name}"]

    # This will create 1 instances
    count = 1
    lifecycle = {
      create_before_destroy = true  
    }
}