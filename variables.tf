variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/22"
}

variable "public_subnet_a" {
  description = "The CIDR blocks for the public subnets."
  type        = string
  default     =  "10.10.0.0/25"
}

variable "public_subnet_c" {
  description = "The CIDR blocks for the public subnets."
  type        = string
  default     =  "10.10.0.128/25"
}

variable "private_subnet_a" {
  description = "The CIDR blocks for the private subnets."
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_c" {
  description = "The CIDR blocks for the private subnets."
  type        = string 
  default     = "10.10.2.0/24"
}

variable "private_subnet_2a" {
  description = "The CIDR blocks for the private subnets."
  type        = string 
  default     = "10.10.3.0/25"
}

variable "private_subnet_2c" {
  description = "The CIDR blocks for the private subnets."
  type        = string
  default     = "10.10.3.128/25"
}
