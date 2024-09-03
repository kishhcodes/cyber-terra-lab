#Create a VPC
resource "aws_vpc" "lab_vpc"{
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Homelab VPC"
  }
}

#Create a Public subnet
resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.lab_vpc.id
    cidr_block = var.public_subnet_cidr
    
    tags = {
        Name = "Homelab subnet"
    }
}

#Create an Internet Gateway
resource "aws_internet_gateway" "home_igw"{
    vpc_id = aws_vpc.lab_vpc.id

    tags = {
        Name = "Homelab VPC I-Gateway"
    }
}

#Create a routing table
resource "aws_route_table" "homelab_rt" {
  vpc_id = aws_vpc.lab_vpc.id
}

#Routing to the internet
resource "aws_route" "routing"{
   route_table_id = aws_route_table.homelab_rt.id
   destination_cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.home_igw.id
}

#Creating an Association for IGW
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.homelab_rt.id
}

#Creating a security group
resource "aws_security_group" "kali-win-machine" {
  name        = "kali-win-machine"
  description = "Security group for Kali linux and Windows machines"
  vpc_id      = aws_vpc.lab_vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1  # ICMP type and code (-1 means all)
    to_port     = -1  # ICMP type and code (-1 means all)
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "soc_tools"{
    name        = "ubuntu-machine"
    description = "Security group for Ubuntu machine"
    vpc_id      = aws_vpc.lab_vpc.id

    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress{
        from_port = 3389
        to_port = 3389
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress{
        from_port = 5900
        to_port = 5920
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress{
        from_port = 9997
        to_port = 9997
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress{
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#Create a Windows Instance with a Key
resource "aws_instance" "windows-server"{
    ami = "ami-07cc1bbe145f35b58"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id

    key_name = var.ssh_key

    security_groups = [ aws_security_group.kali-win-machine.id ]
    associate_public_ip_address = true

    root_block_device {
    volume_size = 30 # Specify the desired size in GB
  }

  tags = { 
    Name = "Homelab [Windows 10]"
  }
}

#Create a Kali Linux instance
resource "aws_instance" "kali-linux"{
    ami = "ami-04a3871e3103ebe8f"
    instance_type = "t2.medium"
    subnet_id = aws_subnet.public_subnet.id

    key_name = var.ssh_key
    
    security_groups = [ aws_security_group.kali-win-machine.id ]
    associate_public_ip_address = true

    root_block_device {
    volume_size = 12 # Specify the desired size in GB
  }

    tags = {
        Name = "Homelab [Kali]"
    }
}

#Create a Ubuntu SOC tool lab
resource "aws_instance" "ubuntu-soc"{
    ami = "ami-00d38fd9bb8c64b19"
    instance_type = "t2.medium"
    subnet_id = aws_subnet.public_subnet.id

    key_name = var.ssh_key

    security_groups = [aws_security_group.soc_tools.id]
    associate_public_ip_address = true

    root_block_device {
    volume_size = 30 # Specify the desired size in GB
  }

    tags = {
        Name = "Homelab (Ubuntu)"
    }
}

output "instance_public_ip_win" {
  value = "Windows Box IP Address: ${aws_instance.windows-server.public_ip}"
}

# Output Kali IP Address.
output "instance_public_ip_kali" {
  value = "Kali Box IP Address: ${aws_instance.kali-linux.public_ip}"
}

# Output Security Tools IP Address.
output "instance_public_ip_security-tools" {
  value = "Security Tools Box IP Address: ${aws_instance.ubuntu-soc.public_ip}"
}