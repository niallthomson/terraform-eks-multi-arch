locals {
  private_subnets    = [for i, n in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i)]
  public_seed_cidr   = cidrsubnet(var.vpc_cidr, 4, length(var.availability_zones))
  public_subnets     = [for i, n in var.availability_zones : cidrsubnet(local.public_seed_cidr, 2, i)]
  database_seed_cidr = cidrsubnet(local.public_seed_cidr, 2, length(var.availability_zones))
  database_subnets   = [for i, n in var.availability_zones : cidrsubnet(local.database_seed_cidr, 2, i)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"
  name    = "${var.environment_name}-vpc"
  azs     = var.availability_zones
  cidr    = var.vpc_cidr

  private_subnets              = local.private_subnets
  public_subnets               = local.public_subnets
  database_subnets             = local.database_subnets
  enable_dns_hostnames         = true
  enable_dns_support           = true
  enable_nat_gateway           = true
  enable_vpn_gateway           = true
  single_nat_gateway           = true
  one_nat_gateway_per_az       = false
  public_dedicated_network_acl = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.environment_name}" = "shared"
    },
  )

  enable_ecr_dkr_endpoint              = true
  ecr_dkr_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_security_group_ids  = [aws_security_group.vpc_endpoint.id]
  enable_s3_endpoint                   = true
  enable_dynamodb_endpoint             = true
}

# Security Group configuration for VPC endpoints
resource "random_id" "vpc_endpoint_sg_suffix" {
  byte_length = 4
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.environment_name}-sg-${random_id.vpc_endpoint_sg_suffix.hex}"
  description = "Security Group used by VPC Endpoints."
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.environment_name}-sg-${random_id.vpc_endpoint_sg_suffix.hex}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "vpc_endpoint_egress" {
  security_group_id = aws_security_group.vpc_endpoint.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "vpc_endpoint_self_ingress" {
  security_group_id        = aws_security_group.vpc_endpoint.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.vpc_endpoint.id
}

// Setup network ACLs for fine-grained control over AZ outage simulation
resource "aws_network_acl" "main" {
  count = length(var.availability_zones)

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.private_subnets[count.index]]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.environment_name}-private-${count.index}"
  }
}

resource "aws_security_group" "provisioner" {
  name        = "${var.environment_name}-provisioner-sg"
  description = "Allow SSH access to provisioner host and outbound internet access"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}