output "task_definitions" {
  value = {for k, v in aws_ecs_task_definition.this : k => v.arn}
}
