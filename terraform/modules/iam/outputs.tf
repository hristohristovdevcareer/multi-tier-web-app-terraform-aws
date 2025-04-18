output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role" {
  value = aws_iam_role.ecs_task_role
}

output "ecs_task_execution_role" {
  value = aws_iam_role.ecs_task_execution_role
}

