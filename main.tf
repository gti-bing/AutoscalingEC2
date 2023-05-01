// define resource provider to be AWS
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile = "iam_terraform"
  region = terraform.workspace == "default" ? "us-west-2" : "us-east-1"
}
// EC2 AMI for Data Engineering Module (ami-09cfe9d7d8c7ed99f)
data "aws_ssm_parameter" "qiime2Ami" {
  name = "qiime2-server"
}

//EC2 AMI for Data Collection API (ami-00616fba1c6cd360c)
data "aws_ssm_parameter" "datacollectionapi" {
  name="datacollectionapi"
}

//EC2 AMI for Post Processor API (ami-0413813467ad9f98a)
data "aws_ssm_parameter" "postprocessorapi" {
  name="postprocessorapi"
}

//EC2 AMI for website server (ami-05df5e71da6167ac5)
data "aws_ssm_parameter" "linuxAmi" {
  name = "webserver-custom"
}



#Create and bootstrap EC2 for website
resource "aws_instance" "ec2-webserver-vm" {
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name = var.generated_key_name
  vpc_security_group_ids      = [aws_security_group.sg.id]
  iam_instance_profile        = aws_iam_instance_profile.main.name
  subnet_id                   = aws_subnet.public_subnet.id
  tags = {
    Name = "${terraform.workspace}-public-webserver-ec2"
  }
  user_data = <<EOF
  #!/bin/bash
  sudo su
  yum update -y
  chmod 600 /home/ubuntu/.s3fs-creds
  s3fs qiime2storage /home/ubuntu/qiime2storage  -o passwd_file=$HOME/.s3fs-creds,nonempty,rw,allow_other,mp_umask=002,uid=1000,gid=1000 -o url=http://s3.us-west-2.amazonaws.com,endpoint=us-west-2,use_path_request_style
  systemctl restart gunicorn
  systemctl restart nginx
  EOF
}



#Create and bootstrap EC2 for Data Collection API
resource "aws_instance" "ec2-datacollectionapi-vm" {
  ami                         = data.aws_ssm_parameter.datacollectionapi.value
  instance_type               = "t3.large"
  associate_public_ip_address = false
  key_name = var.generated_key_name
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.private_subnet.id
  tags = {
    Name = "${terraform.workspace}-private-datacollectionapi-ec2"
  }
  user_data = <<EOF
  #!/bin/bash
  sudo su
  yum update -y
  chmod 600 /home/qiime2/.s3fs-creds
  s3fs qiime2storage /home/qiime2/qiime2storage  -o passwd_file=$HOME/.s3fs-creds,nonempty,rw,allow_other,mp_umask=002,uid=1001,gid=1001 -o url=http://s3.us-west-2.amazonaws.com,endpoint=us-west-2,use_path_request_style
  mkdir -pv /var/{log,run}/gunicorn/
  chown -cR qiime2:qiime2 /var/{log,run}/gunicorn/
  supervisord -c /etc/supervisor/celery.conf 
  service nginx start 
  cd DataCollectionService/
  source venv/bin/activate
  gunicorn -c config/dev.py
  EOF
}


#Create and bootstrap EC2 for Post Processor API
resource "aws_instance" "ec2-postprocessorapi-vm" {
  ami                         = data.aws_ssm_parameter.postprocessorapi.value
  instance_type               = "t3.large"
  associate_public_ip_address = false
  key_name = var.generated_key_name
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.private_subnet.id
  tags = {
    Name = "${terraform.workspace}-private-postprocessorapi-ec2"
  }
  user_data = <<EOF
  #!/bin/bash
  sudo su
  yum update -y
  chmod 600 /home/qiime2/.s3fs-creds
  s3fs qiime2storage /home/qiime2/qiime2storage  -o passwd_file=$HOME/.s3fs-creds,nonempty,rw,allow_other,mp_umask=002,uid=1001,gid=1001 -o url=http://s3.us-west-2.amazonaws.com,endpoint=us-west-2,use_path_request_style
  mkdir -pv /var/{log,run}/gunicorn/
  chown -cR qiime2:qiime2 /var/{log,run}/gunicorn/
  supervisord -c /etc/supervisor/celery.conf 
  service nginx start 
  cd PostProcessorService/
  source venv/bin/activate
  gunicorn -c config/dev.py
  EOF
}