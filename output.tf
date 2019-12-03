output "cluster_description" {
  value = "${data.aws_ecs_cluster.cluster}"
}

output "ecs_role" {
  value = "${data.aws_iam_role.ec2Role}"
}

#output "task_definition_version" {
#  value = "${data.aws_ecs_task_definition.service}"
#}

