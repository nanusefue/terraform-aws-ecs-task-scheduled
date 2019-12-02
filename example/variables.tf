variable "cluster_name" {}
variable "container_name" {}
variable "name_iam_role" {}
variable "rule_description" {}
variable "prefix" {}
variable "env" {}
variable "service" {}
variable "crontabs" {
  type =list(object(
    {
    task_definition = string
    rule_name = string
    event_target_id = string
    schedule_expression = string
    command = string
  }))
  description= "cron definition for ..."
}