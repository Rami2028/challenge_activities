# Define provider
provider "aws" {
  region = "us-west-2"  # Update with your desired region
}

# Create VPC
resource "aws_vpc" "sandbox_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets
resource "aws_subnet" "public_subnet_az1" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"  # Update with your desired AZ
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"  # Update with your desired AZ
}

# Create private subnets
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2a"  # Update with your desired AZ
}

resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b"  # Update with your desired AZ
}

# Create internet gateway
resource "aws_internet_gateway" "sandbox_igw" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

# Create routing tables
resource "aws_route_table" "public_rt_az1" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

resource "aws_route_table" "public_rt_az2" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

resource "aws_route_table" "private_rt_az1" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

resource "aws_route_table" "private_rt_az2" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

# Create routes for public routing tables
resource "aws_route" "public_rt_az1_internet" {
  route_table_id         = aws_route_table.public_rt_az1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sandbox_igw.id
}

resource "aws_route" "public_rt_az2_internet" {
  route_table_id         = aws_route_table.public_rt_az2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sandbox_igw.id
}

# Associate public subnets with public routing tables
resource "aws_route_table_association" "public_subnet_az1_association" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt_az1.id
}

resource "aws_route_table_association" "public_subnet_az2_association" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_rt_az2.id
}

# Associate private subnets with private routing tables
resource "aws_route_table_association" "private_subnet_az1_association" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_rt_az1.id
}

resource "aws_route_table_association" "private_subnet_az2_association" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_rt_az2.id
}











data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Amazon
}

# Create EC2 instance with WordPress in public subnet AZ1
resource "aws_instance" "wordpress_instance" {
  ami           = data.aws_ami.latest_amazon_linux.id  # Replace with your desired AMI ID
  instance_type = "t2.micro"                # Replace with your desired instance type
  vpc_security_group_ids = [aws_security_group.devVPC_sg_allow_ssh_http.id]
  subnet_id     = aws_subnet.public_subnet_az1.id
  tags = {
        Name = "terraform15_ec2_for_public_subnet1_az1"
    }
key_name               = "vockey"
  user_data = <<-EOF
              #!/bin/bash

# System-Update
sudo yum update -y

# Installation von Apache, MariaDB, PHP und zusätzlichen Paketen
sudo yum install -y httpd mariadb-server php php-mysqlnd unzip

# EPEL und Remi Repository für PHP 7.4 hinzufügen
sudo amazon-linux-extras install epel
sudo yum install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# PHP 7.4 aktivieren und benötigte PHP-Pakete installieren
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata
sudo yum install php-cli php-pdo php-fpm php-json php-mysqlnd php php-{mbstring,json,xml,mysqlnd}

# Starten und Aktivieren von Apache und MariaDB
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl start mariadb
sudo systemctl enable mariadb
# WordPress herunterladen und konfigurieren
cd /var/www/html
sudo curl -LO https://wordpress.org/latest.zip
sudo unzip latest.zip
sudo mv -f wordpress/* ./
sudo rm -rf wordpress latest.zip
sudo chown -R apache:apache /var/www/html

# Konfiguration von MariaDB für WordPress
sudo mysql -e "CREATE DATABASE wordpress;"
sudo mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

sudo yum update -y

# Neustart von Apache um alle Änderungen zu übernehmen
sudo systemctl restart httpd

# Überprüfung der PHP-Version
php -v
sudo yum update -y
              EOF

 
}


