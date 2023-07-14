variable "AWS_REGION"{
    default="us-west-2"
    description="AWS Region"
}

variable "cidr_blocks"{
    default = "0.0.0.0/0"
}


variable "public_cidr1"{
    default = "10.0.1.0/24"
}
variable "private_cidr1"{
    default = "10.0.2.0/24"
}
variable "public_cidr2"{
    default = "10.0.1.0/24"
}
variable "private_cidr2"{
    default = "10.0.2.0/24"
}