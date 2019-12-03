data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.cluster_name}" 
}

data "aws_iam_role" "ec2Role" {
  name = "${var.name_iam_role}"
}

#data "aws_ecs_task_definition" "service" {
#  count = "${length(var.crontabs)}"
#  task_definition = "${var.crontabs[count.index].task_definition}"
#}

resource "aws_cloudwatch_event_rule" "scheduled_task" {
  count = "${length(var.crontabs)}"
  name                 = "${var.prefix}-${var.service}-${var.env}-${var.crontabs[count.index].rule_name}" #ec2_scheduled_task"
  description          = "${var.rule_description} ${var.service} ${var.crontabs[count.index].rule_name} ${var.env}"
  schedule_expression  = "${var.crontabs[count.index].schedule_expression}"
}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  count = "${length(var.crontabs)}"
  target_id ="${var.crontabs[count.index].rule_name}-${var.crontabs[count.index].event_target_id}"
  rule      = "${aws_cloudwatch_event_rule.scheduled_task[count.index].name}"
  arn       = "${data.aws_ecs_cluster.cluster.arn}"
  role_arn  = "${data.aws_iam_role.ec2Role.arn}"
  ecs_target {
    task_count          = "1"
    #XEIC#task_definition_arn = "${data.aws_ecs_task_definition.service[count.index].id}"
    task_definition_arn = aws_ecs_task_definition.default[0].arn
  }

input = <<DOC
{
  "containerOverrides": [
    {
      "name": "${var.container_name}",
      "command":${var.crontabs[count.index].command}
    }
  ]
}
DOC
}



# ECS Task Definitions # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html # https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html
resource "aws_ecs_task_definition" "default" {
  #XEIC#count = "${var.enabled == true ? 1 : 0}"
  count = "${length(var.crontabs)}"

  # A unique name for your task definition.
  family = var.service

  # The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
  execution_role_arn = var.create_ecs_task_execution_role ? join("", aws_iam_role.ecs_task_execution.*.arn) : var.ecs_task_execution_role_arn

  # A list of container definitions in JSON format that describe the different containers that make up your task.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
  container_definitions = data.template_file.container_definitions_data.rendered

  # The number of CPU units used by the task.
  # It can be expressed as an integer using CPU units, for example 1024, or as a string using vCPUs, for example 1 vCPU or 1 vcpu.
  # String values are converted to an integer indicating the CPU units when the task definition is registered.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
  cpu = var.cpu

  # The amount of memory (in MiB) used by the task.
  # It can be expressed as an integer using MiB, for example 1024, or as a string using GB, for example 1GB or 1 GB.
  # String values are converted to an integer indicating the MiB when the task definition is registered.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
  memory = var.memory

  # The launch type that the task is using.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#requires_compatibilities
  requires_compatibilities = var.requires_compatibilities

  # Fargate infrastructure support the awsvpc network mode.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#network_mode
  network_mode = "awsvpc"

  # A mapping of tags to assign to the resource.
  tags = merge(
    {
      "Name" = var.service
    },
    var.tags,
  )
}

data "template_file" "container_definitions_data" {
  count    = "${length(var.crontabs)}"
  template = file("policies/container_definitions.json")
  vars = {
    command        = "${var.ecs_task_command == "[]" ? "null" : var.ecs_task_command}"
    taskname       = "${var.taskname}"
    image          = "${var.image}"
    awslogs_region = data.aws_region.current.name
    awslogs_group  = "${var.awslogs_group}"
  }
}

data "aws_region" "current" {
}

