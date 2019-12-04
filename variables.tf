variable "cluster_name" {}
variable "container_name" {}
variable "name_iam_role" {}
variable "rule_description" {}
variable "crontabs" {}
variable "taskname" {}
variable "env" {}

# TD task definitions
#variable "container_definitions" {
#  type        = string
#  description = "TD A list of valid container definitions provided as a single valid JSON document."
#}

#variable "event_target_id" {
#  default = ""
#  type    = string
#}

variable "task_count" {
  default     = 1
  type        = string
  description = "The number of tasks to create based on the TaskDefinition."
}

variable "subnets" {
  type        = list(string)
  description = "The subnets associated with the task or service."
}

variable "platform_version" {
  default     = "LATEST"
  type        = string
  description = "Specifies the platform version for the task."
}

variable "assign_public_ip" {
  default     = false
  type        = string
  description = "Assign a public IP address to the ENI (Fargate launch type only)."
}

variable "security_groups" {
  default     = []
  type        = list(string)
  description = "The security groups associated with the task or service."
}

variable "cpu" {
  default     = "256"
  type        = string
  description = "TD The number of cpu units used by the task."
}

variable "memory" {
  default     = "512"
  type        = string
  description = "TD The amount (in MiB) of memory used by the task."
}

variable "requires_compatibilities" {
  default     = ["FARGATE"]
  type        = list(string)
  description = "TD A set of launch types required by the task. The valid values are EC2 and FARGATE."
}

variable "iam_path" {
  default     = "/"
  type        = string
  description = "Path in which to create the IAM Role and the IAM Policy."
}

variable "description" {
  default     = "Managed by Terraform"
  type        = string
  description = "The description of the all resources."
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "TD A mapping of tags to assign to all resources."
}

variable "enabled" {
  default     = true
  type        = bool
  description = "TD Set to false to prevent the module from creating anything."
}

variable "create_ecs_task_execution_role" {
  default     = true
  type        = string
  description = "Specify true to indicate that ECS Task Execution IAM Role creation."
}

variable "ecs_task_execution_role_arn" {
  default     = ""
  type        = string
  description = "The ARN of the ECS Task Execution IAM Role."
}
