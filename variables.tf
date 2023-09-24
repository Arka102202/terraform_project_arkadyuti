variable "aws_region" {
  description = "AWS region where the resources will be created."
  default     = "us-east-1"  # Change to your desired region.
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group."
  default     = "t2.micro"   # Change as needed.
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  default     = 2            # Change as needed.
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  default     = 1            # Change as needed.
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  default     = 3            # Change as needed.
}

variable "private_key_path" {
  default     = "provider-rsa.pem"            # Change as needed.
}

variable "ami_id" {
  default     = "ami-03a6eaae9938c858c"            # Change as needed.
}


