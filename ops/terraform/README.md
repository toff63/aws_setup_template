# Building environments with Terraform

# Environment skeleton

## VPC architecture

The VPC architecture is based on the [AWS VPC reference](http://docs.aws.amazon.com/quickstart/latest/vpc/architecture.htmlhttp://docs.aws.amazon.com/quickstart/latest/vpc/architecture.html).
The current design organizes the VPC like the following:

<img align="center" alt="VPC architecture" src="../readme/vpc_archi.png">


Public subnet have public IP addresses while private subnet don't. Instances in public subnets can access the Internet directly while instances in private subnet have a route going through the NAT gateway to the Internet.

## Implementation

The module directory contains a network directory which defines each peace of infrastructure needed to deploy the architecture above. Each terraform expects a list of variables in order to customize the setting.

Environments are defined in the `environment directory` where each directory inside defines an environment. The global directory defines what is shared between environment, currently, the application dns domain. It also uses S3 to store the state and Dynamodb to store the lock on this state.

### Staging environment

The configuration is in environments/eu-west-1-dev/ directories. In `eu-west-1-dev.tf` we define:
* aws provider config which should come from variables
* where to store terraform remote state in s3 using Dynamodb table for lock
* data coming from the global terraform execution
* bastion key pair
* network module with variables

Those variables values are defined in terraform.tfvars file which is in the same directory.


## Deploying

### Setup

Create a file in `$HOME/.aws_once.tfvars` with:
```
region = "eu-west-1"
access_key = "YOUR ACCESS KEY"
secret_key = "YOUR SECRET KEY"
role_arn = "arn:aws:iam::760853363913:role/BackendRole"
```
### Execution

#### Init global

Go in `environments/global`
```sh
terraform init -backend=true -backend-config=$HOME/.aws_once.tfvars
terraform plan -var-file=global.tfvars -var-file=$HOME/.aws_once.tfvars
terraform apply -var-file=global.tfvars -var-file=$HOME/.aws_once.tfvars

```


#### Create dev

Go in `environments/eu-west-1-dev`

```sh
terraform init -backend=true -backend-config=$HOME/.aws_once.tfvars
terraform plan -var-file=terraform.tfvars -var-file=$HOME/.aws_once.tfvars
terraform apply -var-file=terraform.tfvars -var-file=$HOME/.aws_once.tfvars
```


#### Destroy an enviroment

This is obviously something you should be **very** careful with.

To destroy dev:
From `environments/eu-west-1-dev`

```sh
terraform destroy -var-file=terraform.tfvars -var-file=$HOME/.aws_once.tfvars
```

To destory global:
From `environments/global`
```sh
terraform destroy -var-file=global.tfvars -var-file=$HOME/.aws_once.tfvars
```
