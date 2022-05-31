data "aws_iam_role" "task_execution" {
  name = "ecsTaskExecutionRole"
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = merge([
  for t in var.task_definitions : {
  for c in t.container_definitions : "${var.cluster_name}${try(t.name, null) == null ? "" : "/${t.name}"}${try(c.name, null) == null ? "" : "/${c.name}"}" => {
    log_retention_days = try(c.log_retention_days, 7)
  }
  }
  ]...)
  name              = "/ecs/${each.key}"
  retention_in_days = each.value.log_retention_days
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  for_each                 = {for i, t in var.task_definitions : i => t}
  family                   = "${var.cluster_name}${try(each.value.name, null) == null ? "" : "-${each.value.name}"}"
  requires_compatibilities = try(each.value.requires_compatibilities, ["EC2"])
  execution_role_arn       = data.aws_iam_role.task_execution.arn
  task_role_arn            = try(each.value.task_role_arn, null)
  network_mode             = try(each.value.network_mode, "bridge")
  cpu                      = try(each.value.cpu, null)
  memory                   = try(each.value.memory, null)
  tags                     = var.tags

  dynamic "runtime_platform" {
    for_each = try(each.value.runtime_platform, null) != null ? [1] : []

    content {
      operating_system_family = try(each.value.runtime_platform.operating_system_family, "LINUX")
      cpu_architecture        = try(each.value.runtime_platform.cpu_architecture, "X86_64")
    }
  }

  dynamic "volume" {
    for_each = try(each.value.volumes, [])

    content {
      name      = volume.value.name
      host_path = try(volume.value.host_path, null)

      dynamic "efs_volume_configuration" {
        for_each = try(volume.value.efs_volume_configuration, [])

        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = try(efs_volume_configuration.value.root_directory, null)
          transit_encryption      = try(efs_volume_configuration.value.transit_encryption, null)
          transit_encryption_port = try(efs_volume_configuration.value.transit_encryption_port, null)

          dynamic "authorization_config" {
            for_each = try(efs_volume_configuration.value.authorization_config, [])

            content {
              iam             = try(authorization_config.value.iam_auth, null)
              access_point_id = try(authorization_config.value.access_point_id, null)
            }
          }
        }
      }
    }
  }

  container_definitions = jsonencode([
  for c in each.value.container_definitions : {
    name              = c.name
    image             = c.image
    cpu               = c.cpu
    memoryReservation = c.memoryReservation
    essential         = try(c.essential, true)
    dependsOn         = try(c.dependsOn, null)
    portMappings      = try(c.portMappings, null)
    healthCheck       = try(c.healthCheck, null)
    linuxParameters   = try(c.linuxParameters, null)
    environment       = try(c.environment, null)
    entryPoint        = try(c.entryPoint, null)
    command           = try(c.command, null)
    workingDirectory  = try(c.workingDirectory, null)
    secrets           = try(c.secrets, null)
    mountPoints       = try(c.mountPoints, null)
    logConfiguration : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-region" : var.region,
        "awslogs-group" : aws_cloudwatch_log_group.this["${var.cluster_name}${try(each.value.name, null) == null ? "" : "/${each.value.name}"}${try(c.name, null) == null ? "" : "/${c.name}"}"].name,
        "awslogs-stream-prefix" : "ecs"
      }
    }
  }
  ])
}
