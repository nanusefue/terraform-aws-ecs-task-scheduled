# ecs-task-scheduled

**module**
```
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
```

**tfvars**
```
    cluster_name        ="ecs-cluster-name"
    container_name      ="container-name"
    name_iam_role       ="ecsEventsRole"
    rule_description    ="Cronjob run"
    env                 ="prd" #ver si utilizamos este value
    prefix              ="cron"
    service             ="service-name""
    crontabs = [
        {
            task_definition     ="task-definition"
            rule_name           ="rule-name"
            event_target_id     ="uixu"
            schedule_expression ="cron(0/30 * * * ? *)"
            command             ="[\"php\",\"app/console\",\"catalog:reindex:issue\",\"--env=prod\"]"

        }]
```