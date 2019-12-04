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
  name                 = "${var.crontabs[count.index].taskname}" #ec2_scheduled_task"
  description          = "${var.rule_description} ${var.crontabs[count.index].taskname}"
  schedule_expression  = "${var.crontabs[count.index].schedule_expression}"
}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  count     = "${length(var.crontabs)}"
  target_id = "${var.crontabs[count.index].taskname}-${var.crontabs[count.index].event_target_id}"
  rule      = "${aws_cloudwatch_event_rule.scheduled_task[count.index].name}"
  arn       = "${data.aws_ecs_cluster.cluster.arn}"
  role_arn  = "${data.aws_iam_role.ec2Role.arn}"
  ecs_target {
    launch_type         = "FARGATE"
    task_count          = var.task_count
    task_definition_arn = aws_ecs_task_definition.default[count.index].arn

    # Specifies the platform version for the task. Specify only the numeric portion of the platform version, such as 1.1.0.
    # This structure is used only if LaunchType is FARGATE.
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform_versions.html
    platform_version = var.platform_version

    # This structure specifies the VPC subnets and security groups for the task, and whether a public IP address is to be used.
    # This structure is relevant only for ECS tasks that use the awsvpc network mode.
    # https://docs.aws.amazon.com/AmazonCloudWatchEvents/latest/APIReference/API_AwsVpcConfiguration.html
    network_configuration {
      assign_public_ip = var.assign_public_ip

      # Specifies the security groups associated with the task. These security groups must all be in the same VPC.
      # You can specify as many as five security groups. If you do not specify a security group,
      # the default security group for the VPC is used.
      security_groups = var.security_groups

      # Specifies the subnets associated with the task. These subnets must all be in the same VPC.
      # You can specify as many as 16 subnets.
      subnets = var.subnets
    }
  }


#input = <<DOC
#{
#  "containerOverrides": [
#    {
#      "name": "${var.container_name}",
#      "command":${var.crontabs[count.index].command}
#    }
#  ]
#}
#DOC
}

# ECS Task Definitions # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html # https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html
resource "aws_ecs_task_definition" "default" {
  count = "${length(var.crontabs)}"

  # A unique name for your task definition.
  family = "${var.crontabs[count.index].taskname}" #ec2_scheduled_task"

  # The ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
  execution_role_arn = var.create_ecs_task_execution_role ? join("", aws_iam_role.ecs_task_execution.*.arn) : var.ecs_task_execution_role_arn

  # A list of container definitions in JSON format that describe the different containers that make up your task.
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions
  container_definitions = "${element(data.template_file.container_definitions_data.*.rendered, count.index)}"

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
      "Name" = "${var.crontabs[count.index].taskname}"
    },
    var.tags,
  )
}

data "template_file" "container_definitions_data" {
  count    = "${length(var.crontabs)}"
  template = file("policies/container_definitions.json")
  vars = {
    command        = "${var.crontabs[count.index].command}"
    taskname       = "${var.crontabs[count.index].taskname}"
    image          = "${var.crontabs[count.index].image}"
    awslogs_region = data.aws_region.current.name
    awslogs_group  = "${var.crontabs[count.index].awslogs_group}"
  }
}

data "aws_region" "current" {
}

# ECS Task Execution IAM Role # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html # https://www.terraform.io/docs/providers/aws/r/iam_role.html
resource "aws_iam_role" "ecs_task_execution" {
  count    = "${length(var.crontabs)}"

  name               = "${var.crontabs[count.index].taskname}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role_policy.json
  path               = var.iam_path
  description        = var.description
  #tags = merge(
  #  {
  #    "Name" = "${var.crontabs[count.index].taskname}-ecs-task-execution"
  #  },
  #  var.tags,
  #)
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role_policy" {
  count    = "${length(var.crontabs)}"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
resource "aws_iam_policy" "ecs_task_execution" {
  count    = "${length(var.crontabs)}"

  name        = "${var.crontabs[count.index].taskname}"
  policy      = data.aws_iam_policy.ecs_task_execution.policy
  path        = var.iam_path
  description = var.description
}

# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count = local.enabled_ecs_task_execution

  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = aws_iam_policy.ecs_task_execution[0].arn
}

locals {
  enabled_ecs_task_execution  = var.enabled && var.create_ecs_task_execution_role ? 1 : 0
}

data "aws_iam_policy" "ecs_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
