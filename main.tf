data "aws_ecs_cluster" "cluster" {
  cluster_name = "${var.cluster_name}" 
}

data "aws_iam_role" "ec2Role" {
  name = "${var.name_iam_role}"
}

data "aws_ecs_task_definition" "service" {
  count = "${length(var.crontabs)}"
  task_definition = "${var.crontabs[count.index].task_definition}"
}

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
    task_definition_arn = "${data.aws_ecs_task_definition.service[count.index].id}"
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
