terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source         = "git::https://github.com/inflearn/terraform-aws-vpc.git?ref=v3.14.0"
  name           = "example-inflab-ecs-ec2"
  cidr           = "10.0.0.0/16"
  azs            = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "security_group_ecs" {
  source      = "git::https://github.com/inflearn/terraform-aws-security-group.git?ref=v4.9.0"
  name        = "example-inflab-ecs-ec2-ecs"
  description = "Security group terraform example elasticache"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 32768
      to_port                  = 65535
      protocol                 = 6
      description              = "HTTP from ALB"
      source_security_group_id = module.security_group_alb.security_group_id
    },
  ]
  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "ecs_cluster" {
  source                    = "../../"
  cluster_name                      = "example-inflab-ecs-cluster"
  type                      = "FARGATE"
  enable_container_insights = true

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}
