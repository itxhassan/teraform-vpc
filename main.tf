data "aws_availability_zones" "available" {}


resource "aws_vpc" "this" {
cidr_block = var.vpc_cidr
enable_dns_support = true
enable_dns_hostnames = true
tags = { Name = "${var.name_prefix}-vpc" }
}


resource "aws_subnet" "public" {
for_each = { for idx, cidr in var.public_subnets : idx => cidr }
vpc_id = aws_vpc.this.id
cidr_block = each.value
availability_zone = data.aws_availability_zones.available.names[each.key]
map_public_ip_on_launch = true
tags = { Name = "${var.name_prefix}-public-${each.key}" }
}


resource "aws_internet_gateway" "gw" { vpc_id = aws_vpc.this.id, tags = { Name = "${var.name_prefix}-igw" } }


resource "aws_route_table" "public" {
vpc_id = aws_vpc.this.id
route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.gw.id }
tags = { Name = "${var.name_prefix}-public-rt" }
}


resource "aws_route_table_association" "public_assoc" {
for_each = aws_subnet.public
subnet_id = each.value.id
route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "allow_ssh_http" {
name = "${var.name_prefix}-sg"
vpc_id = aws_vpc.this.id
ingress {
from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
}
egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
tags = { Name = "${var.name_prefix}-sg" }
}