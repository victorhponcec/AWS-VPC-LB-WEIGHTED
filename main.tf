#Configuring AWS Provider
provider "aws" {
  region = "us-east-1"
}
# Tags For Resources ###   tags       = { vpc = "main", environment = "dev", source = "terraform" }

#VPC 
resource "aws_vpc" "main" {
  cidr_block = "10.111.0.0/16"
}

#Subnet Public
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.1.0/24"
  availability_zone = "us-east-1a"
}

#Subnet Public B
resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.111.2.0/24"
  availability_zone = "us-east-1b"
}

#Subnet Private 
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.111.3.0/24"
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

#EIP for NAT Gateway
resource "aws_eip" "eip_ngw" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

#NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip_ngw.id
  subnet_id     = aws_subnet.public_subnet.id #NGW must be placed in public subnet
  depends_on    = [aws_internet_gateway.igw]
}

#Route Tables
#Public Route table
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
#Private Route Table
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
}

#Create route table associations
#Associate public Subnet to public route table 
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rtb.id
}
#Associate public Subnet to public route table | for Public Subnet B
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rtb.id
}
#Associate private Subnet to private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rtb.id
}

#EC2 Instances
resource "aws_instance" "amazon_linux" {
  ami                         = "ami-05576a079321f21f8"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.web.id, aws_security_group.ssh.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ec2_key.key_name
}

resource "aws_instance" "amazon_linux_private_sbnt" {
  ami                  = "ami-05576a079321f21f8"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.web.id]
  subnet_id            = aws_subnet.private_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
}

#Security Group
resource "aws_security_group" "web" {
  name        = "web"
  description = "allow web traffic"
  vpc_id      = aws_vpc.main.id
}
#ingress rule for Security Group
resource "aws_vpc_security_group_ingress_rule" "allow_443" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
#ingress rule for Security Group
resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
#ingress rule for Security Group
resource "aws_vpc_security_group_ingress_rule" "allow_icmp" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}
#egress rule for Security Group
resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#SSH Config
#Create PEM File
resource "tls_private_key" "pkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
/*
#it won't create PEM file when using remote backend | use with local backend
resource "local_file" "private_key_pem" {
  content  = tls_private_key.pkey.private_key_pem
  filename = "AWSKeySSH.pem"
  file_permission = "0400" #NOT TESTED
}

#AWS SSH EC2 Key Pair -using tls_private_key to generate public key
resource "aws_key_pair" "ec2_key" {
  key_name   = "AWSKeySSH"
  public_key = tls_private_key.pkey.public_key_openssh
 # provisioner "local-exec" { command = "echo '${tls_private_key.pkey.private_key_pem}' > ./AWSKeySSH_2.pem" } # creates PEM file with AWS key #DELETE IF DOESN'T WORK
  
  lifecycle {
    ignore_changes = [key_name] #to ensure it creates a different pair of keys each time
  }
}*/

#AWS SSH EC2 Key Pair -using manually created public key with openssl
resource "aws_key_pair" "ec2_key" {
  key_name   = "AWSKeySSH"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCexvuJWBUNo3HSuI6Ip1l7ZJkr5luYdYbEsiU27wJSmagmkmVQBz3pAL6LuVpsSHODzMTUFIuhG6gnindez6BmpMkRAuMc7BYh6epIxSMKV55SC1i95Ark8JoIn+usm5dg3tgXl0u3DqhuARUhpuvd5dm86m95yXKn+MfqQKxygBgHXB32Wde1TorWUoZTRuoxm3h9US50H/kyNEUKwK0VG5vx4pbmv9Re5ErqY8mambL5pKZW3GDRKjjYDkMdCbGc6DhrSqzFFLHn9Fj/bQlC20eKvny8v1Pwk1rs5pP2CQgqYWnDYYenywfQDRsQfTRCytVAVc4IhQuDnazr2SkB"
}

#Security group to allow SSH
resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "allow SSH (for EC2 instance)"
  vpc_id      = aws_vpc.main.id
}

#Ingress rule for SSH
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}
#Egress rule for SSH
resource "aws_vpc_security_group_egress_rule" "egress_ssh_all" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#Enable SSM on EC2 (pass IAM ROLE AmazonSSMManagedInstanceCore to EC2)
#Create IAM role/Trust Policy
resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#attach Permission Policy to Trust Policy (role)
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#create instance profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# to do
# Create ELB | attach to 2 instances in same AZ | attach to 2 instances in different AZ
# Create AutoScalingGroup Normal
# Create AutoScalingGroup using Modules
