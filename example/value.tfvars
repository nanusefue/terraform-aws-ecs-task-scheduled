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
