provider "aws" {
  region     = "ap-south-1"
  profile    = "shivanshk"
}

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Task3vpc"
  }
}

resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PubSub"
  }
}

resource "aws_subnet" "sub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "PriSub"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Task3vpc_GW"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "main"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "allow_mysql" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "allow_mysql"
  }
}


resource "aws_instance" "mysql" {
  ami           = "ami-003d3121ddd670a08"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.allow_mysql.id ]
  subnet_id = aws_subnet.sub2.id
  user_data = <<-EOF
        
        #!/bin/bash
        sudo docker run -dit -p 8080:3306 --name mysql -e MYSQL_ROOT_PASSWORD=awscloud -e MYSQL_DATABASE=task-db -e MYSQL_USER=shivansh -e MYSQL_PASSWORD=shivansh mysql:5.7
  
  EOF


  tags = {
    Name = "allow_Mysql"
  }
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "Allow tcp for inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_wp"
  }
}



resource  "aws_instance"  "wordpress" {
  ami                          = "ami-003d3121ddd670a08"
  instance_type                = "t2.micro"
  availability_zone            = "ap-south-1a"
  subnet_id                    = aws_subnet.sub1.id
  vpc_security_group_ids       = [ aws_security_group.wordpress_sg.id ]
  associate_public_ip_address  = "true"
  
  user_data = <<-EOF
        #!/bin/bash
        sudo docker run -dit -p 8081:80 --name wp wordpress:5.1.1-php7.3-apache
  EOF

    
  tags = {
    Name = "wordpress"  
  }
}
