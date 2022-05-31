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
  name           = "example-inflab-ecs-task-definition-complete-fargate"
  cidr           = "10.0.0.0/16"
  azs            = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "security_group_ecs" {
  source      = "git::https://github.com/inflearn/terraform-aws-security-group.git?ref=v1.0.0-inflab"
  name        = "example-inflab-ecs-task-definition-complete-fargate"
  description = "Security group terraform example elasticache"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

module "ecs_cluster" {
  source                    = "git::https://github.com/inflearn/terraform-aws-ecs-cluster.git?ref=v1.0.0-inflab"
  name                      = "example-inflab-ecs-task-definition-complete-fargate"
  type                      = "FARGATE"
  enable_container_insights = true

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "ecs_task_definition" {
  source       = "../../"
  cluster_name = "example-inflab-ecs-task-definition-complete-fargate"
  region       = "ap-northeast-2"

  task_definitions = [
    {
      name                     = "task-definition"
      requires_compatibilities = ["FARGATE"]
      task_role_arn            = null
      network_mode             = "awsvpc"
      volumes                  = []
      cpu                      = 256
      memory                   = 512
      runtime_platform         = {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
      }
      container_definitions = [
        {
          name               = "container"
          log_retention_days = 7
          image              = "ubuntu:latest"
          essential          = true
          dependsOn          = null
          portMappings       = null
          healthCheck        = null
          linuxParameters    = null
          environment        = null
          entryPoint         = null
          command            = null
          workingDirectory   = null
          secrets            = null
          mountPoints        = null
        }
      ]
    }
  ]

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}
