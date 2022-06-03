variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "task_definitions" {
  type    = any
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
