

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
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.devVPC_sg_allow_ssh_http.id]
  subnet_id     = aws_subnet.public_subnet_az1.id

  # Tags for the EC2 instance
  tags = {
    Name = "terraform15_ec2_for_public_subnet1_az1"
  }

  key_name  = "vockey"
  user_data = file("userdata.sh")  # Replace "userdata.sh" with the name of your user data file.
}






resource "aws_lb" "wordpress_lb" {
  name               = "wordpress-lb"
  subnets            = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
  security_groups = [aws_security_group.load_balancer_sg.id]
  # Replace with the security group for the load balancer

  tags = {
    Name = "wordpress-lb"
  }
}
resource "aws_security_group" "load_balancer_sg" {
  name_prefix = "load-balancer-sg-"

  vpc_id = aws_vpc.sandbox_vpc.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # You can add more ingress or egress rules as per your requirements
}


resource "aws_lb_target_group" "wordpress_target_group" {
  name        = "wordpress-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.sandbox_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_target_group_attachment" "wordpress_attachment_az1" {
  target_group_arn = aws_lb_target_group.wordpress_target_group.arn
  target_id        = aws_instance.wordpress_instance.id
  port             = 80
}


resource "aws_lb_listener" "wordpress_listener" {
  load_balancer_arn = aws_lb.wordpress_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_target_group.arn
  }
}


resource "aws_autoscaling_group" "wordpress_asg" {
  name        = "wordpress-asg"
  min_size    = 1
  max_size    = 3
  desired_capacity = 2
  health_check_grace_period = 300

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.wordpress_lt.id
        version            = "$Latest"
      }

      override {
        instance_type     = "t2.micro"  # You can change this instance type as needed
        weighted_capacity = "1"
      }
    }
  }

  vpc_zone_identifier = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]

  # Associate the Auto Scaling group with the load balancer target group
  target_group_arns = [aws_lb_target_group.wordpress_target_group.arn]
}

resource "aws_launch_template" "wordpress_lt" {
  name_prefix = "wordpress-lt-"

  image_id           = data.aws_ami.latest_amazon_linux.id
  instance_type      = "t2.micro"  # Change this instance type as needed
  vpc_security_group_ids = [aws_security_group.devVPC_sg_allow_ssh_http.id]
  key_name           = "vockey"

}
