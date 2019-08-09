#--------------------------------------------------------------
# General
#--------------------------------------------------------------

name              = "staging"
full_name         = "staging"
region            = "eu-west-1"
sub_domain        = "eu-west-1.myproduct.staging"


#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

vpc_cidr        = "172.63.0.0/16"
azs             = "eu-west-1a,eu-west-1b,eu-west-1c" # AZs are region specific
private_subnets = "172.63.1.0/24,172.63.2.0/24,172.63.3.0/24" # Creating one private subnet per AZ
public_subnets  = "172.63.11.0/24,172.63.12.0/24,172.63.13.0/24" # Creating one public subnet per AZ

# Bastion
bastion_instance_type = "t2.micro"
bastion_ami_id = "ami-2a7d75c0"
bastion_ingress_cidr = [YOUR IP CIDR]

#
#--------------------------------------------------------------
# Deploy
#--------------------------------------------------------------

domain_name = "api-staging"

bastion_public_key = "YOUR PUBLIC KEY"

api_public_key = "YOUR PUBLIC KEY"
api_instance_type = "t3.medium"
api_cluster_size = 2

api_ingress_cidr = [YOUR IP CIDR]
