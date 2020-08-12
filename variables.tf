# common
variable "prefix" {
    default = "skuser001"
}

# for vpc
variable "vpc1-cidr" {
    default = "10.0.0.0/16"
}

variable "vpc2-cidr" {
    default = "20.0.0.0/16"
}

#for subnet
variable "az-1a" {
    default = "ap-northeast-2a"
}

variable "az-1b" {
    default = "ap-northeast-2c"
}

variable "az-2a" {
    default = "ap-northeast-2a"
}

variable "az-2b" {
    default = "ap-northeast-2c"
}

variable "subnet1a-cidr" {
    default = "10.0.1.0/24"
}

variable "subnet1b-cidr" {
    default = "10.0.2.0/24"
}

variable "subnet2a-cidr" {
    default = "20.0.1.0/24"
}

variable "subnet2b-cidr" {
    default = "20.0.2.0/24"
}


# custom AMI (web server)
variable "amazon_linux" {
    # default = "ami-0f44900104ca6dfb0"
    #default = "ami-0f1e32473158d4d09" // add on pengsu image in index.html
    default = "ami-0a0773ad4412503ac"
}

variable "cloud9-cidr" {
    default = "0.0.0.0/0" // cloud9 public ip addr
}

variable "keyname" {
    default = "skuser001-key"
}

variable "alb_account_id" {
    default = "600734575887" // ap-northeast-2 Asia Pacific (Seoul) 600734575887
}

variable "region" {
    default = "ap-northeast-2" // ap-northeast-2 Asia Pacific (Seoul) 600734575887
}
