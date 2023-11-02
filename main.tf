#Create VPC
resource "aws_vpc" "labvpc" {
  cidr_block = var.cidr
  #cidr_block = "10.0.0.0/16"
}

#Create Subnets
resource "aws_subnet" "labsubnet1" {
  vpc_id                  = aws_vpc.labvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "labsubnet2" {
  vpc_id                  = aws_vpc.labvpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
#Create Internet Gateway
resource "aws_internet_gateway" "labig" {
  vpc_id = aws_vpc.labvpc.id
}
#Internet Gateway Attachement
/* resource "aws_internet_gateway_attachment" "labig" {
  internet_gateway_id = aws_internet_gateway.labig.id
  vpc_id = aws_vpc.labvpc.id
} */
#Create Route Tables
resource "aws_route_table" "labrt" {
  vpc_id = aws_vpc.labvpc.id
  route {
    cidr_block = var.world
    gateway_id = aws_internet_gateway.labig.id
  }
}

#Route Table Association
resource "aws_route_table_association" "labrt1" {
  subnet_id      = aws_subnet.labsubnet1.id
  route_table_id = aws_route_table.labrt.id
}
resource "aws_route_table_association" "labrt2" {
  subnet_id      = aws_subnet.labsubnet2.id
  route_table_id = aws_route_table.labrt.id
}

#Security Group
resource "aws_security_group" "labsg" {
  name   = "web"
  vpc_id = aws_vpc.labvpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.world]
  }
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.world]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### Second block
#Create S3 bucket
resource "aws_s3_bucket" "labs3" {
    bucket = "labs3-tf-lab-bucket"
}
#Create Instances
resource "aws_instance" "web" {
    ami = var.ami
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.labsg.id]
    subnet_id = aws_subnet.labsubnet1.id
    user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "web1" {
    ami = var.ami
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.labsg.id]
    subnet_id = aws_subnet.labsubnet2.id
    user_data = base64encode(file("userdata2.sh"))
}

#### Third Block
#Create Application Load Balancer

resource "aws_lb" "lablb" {
    name = "lablb-webapp"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.labsg.id]
    subnets = [aws_subnet.labsubnet1.id,aws_subnet.labsubnet2.id]

/*     access_logs {
      bucket = aws_s3_bucket.labs3.id
      prefix = "lablb-webapp"
      enabled = true
    } */
}

#Create Target Group
resource "aws_lb_target_group" "lablb-tg" {
    name = "lablb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.labvpc.id

    health_check {
      path = "/"
      port = "traffic-port"
    }
}

#Target Group Attachment

resource "aws_lb_target_group_attachment" "lablb-tg1" {
    target_group_arn = aws_lb_target_group.lablb-tg.arn
    target_id = aws_instance.web.id
    port = 80
}

resource "aws_lb_target_group_attachment" "lablb-tg2" {
    target_group_arn = aws_lb_target_group.lablb-tg.arn
    target_id = aws_instance.web1.id
    port = 80
  
}

#Listener
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.lablb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.lablb-tg.arn
    type = "forward"
  }
}