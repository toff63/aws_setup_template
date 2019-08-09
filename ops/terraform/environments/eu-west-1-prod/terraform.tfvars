#--------------------------------------------------------------
# General
#--------------------------------------------------------------

name              = "prod"
full_name         = "production"
region            = "eu-west-1"
sub_domain        = "eu-west-1.myproduct.prod"

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

vpc_cidr        = "172.64.0.0/16"
azs             = "eu-west-1a,eu-west-1b,eu-west-1c" # AZs are region specific
private_subnets = "172.64.1.0/24,172.64.2.0/24,172.64.3.0/24" # Creating one private subnet per AZ
public_subnets  = "172.64.11.0/24,172.64.12.0/24,172.64.13.0/24" # Creating one public subnet per AZ

# Bastion
bastion_instance_type = "t3.micro"
bastion_ami_id = "ami-2a7d75c0"
bastion_ingress_cidr = ["YOUR CIDR"]
bastion_public_key = "YOUR PUBLIC KEY"

#
#--------------------------------------------------------------
# Deploy
#--------------------------------------------------------------

domain_name = "api-prod"

api_instance_type = "c5.2xlarge"
api_cluster_size = "3"


api_public_key = "YOUR PUBLIC KEY"

api_ingress_cidr = ["0.0.0.0/0"]
