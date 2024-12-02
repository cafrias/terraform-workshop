variable "region" {
  type = string
  default = "us-east-1"
}

variable profile {
  type = string
  default = "default"
}

variable "hello_package" {
  type = string
  default = "lambdas/hello/dist/hello.zip"
}

variable "environment" {
  type = string
}
