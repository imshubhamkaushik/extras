variable "project_name" {
  type        = string
  description = "Logical name of the project"
}

variable "repository_names" {
  type = list(string)
}