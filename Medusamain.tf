resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "medusa-vpc"
  }
}
resource "aws_subnet" "medusa_public_subnet" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "medusa-public-subnet"
  }
}


resource "aws_subnet" "medusa_private_subnet_a" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "medusa-private-subnet-a"
  }
}
resource "aws_subnet" "medusa_private_subnet_b" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "medusa-private-subnet-b"
  }
}
resource "aws_internet_gateway" "medusa_igw" {
  vpc_id = aws_vpc.medusa_vpc.id
  tags = {
    Name = "medusa-igw"
  }
}
resource "aws_route_table" "medusa_public_rt" {
  vpc_id = aws_vpc.medusa_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.medusa_igw.id
  }
  tags = {
    Name = "medusa-public-rt"
  }
}

resource "aws_route_table_association" "medusa_public_rta" {
  subnet_id      = aws_subnet.medusa_public_subnet.id
  route_table_id = aws_route_table.medusa_public_rt.id
}
resource "aws_security_group" "medusa_sg" {
  vpc_id = aws_vpc.medusa_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "medusa-sg"
  }
}
resource "aws_instance" "medusa_instance" {
  ami           = "ami-0182f373e66f89c85"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.medusa_public_subnet.id
  ##security_groups = [aws_security_group.medusa_sg.name]

  tags = {
    Name = "medusa-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d -p 9000:9000 medusajs/medusa
              EOF
}
resource "aws_db_instance" "medusa_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "12.15"
  instance_class       = "db.t3.micro"
  username             = "medusauser"
  password             = "Prayas12345"
  ##parameter_group_name = "aws_db_parameter_group.medusa_custom_pg.name"
  db_subnet_group_name = aws_db_subnet_group.medusa_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.medusa_sg.id]
  skip_final_snapshot  = true

  tags = {
    Name = "medusa-db"
  }
}

resource "aws_db_subnet_group" "medusa_db_subnet_group" {
  name       = "medusa-db-subnet-group"
  subnet_ids = [
    aws_subnet.medusa_private_subnet_a.id,
    aws_subnet.medusa_private_subnet_b.id
  ]
  tags = {
    Name = "medusa-db-subnet-group"
  }
}
output "instance_public_ip" {
  value = aws_instance.medusa_instance.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.medusa_db.endpoint
}

