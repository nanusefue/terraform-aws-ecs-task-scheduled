module "ecs-task-scheduled" {
  source  = "nanusefue/ecs-task-scheduled/aws"
  version = "0.0.2"
    cluster_name        = "${var.cluster_name}"
    container_name      = "${var.container_name}"
    name_iam_role       = "${var.name_iam_role}"
    rule_description    = "${var.rule_description}"
    crontabs            = "${var.crontabs}"
    env                 = "${var.env}"
    prefix              = "${var.prefix}"
    service             = "${var.service}"
}