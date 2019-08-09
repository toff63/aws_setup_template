This guide help you to setup your AWS account, create environments and then deploy new code version. It assumes you are familiar with AWS console and have packer and terraform 0.12 installed.

# Table of Contents
1. [Prepare AWS account](#prepare-aws-account)
2. [Staging](#staging)
	1. [First staging AMI](#first-staging-ami)
	2. [Create staging environment](#create-staging-environment)
	3. [Deploy staging](#deploy-staging)
2. [Production](#production)
	1. [First production AMI](#first-production-ami)
	2. [Create production environment](#create-production-environment)
	3. [Deploy production](#deploy-production)
4. [Tear down an environment](#tear-down-an-environment)

# Prepare AWS account

In this part we do a couple of things manually to be able to execute the global terraform so we have the bare minimum to generate AMIs with Packer and then create environments.

1. Create user with administration access
2. Get access key and shared secret and add them in ~/.aws/credentials under the profile `aws_template`. Don't forget to specify the region.
3. Create file named ~/.aws/terraform (this is not standard and you can put it anywhere you want) with the following
region = "eu-west-1"
access_key = "YOUR ACCESS KEY"
secret_key = "YOUR SECRET KEY"
4. In AWS console create a s3 bucket named `terraform-remote-state-my-product` (it will contain terraform remote state)
5. Create dynamodb table named `terraform-my-product-lock` and primary key `LockID` of type `String`
6. Register your domain certificate in us-east-1 region in Amazon console. The terraform expect a wildcard certificate (*.myproduct.com)
7. Register your domain certificate in the region you are planning to deploy (eu-west-1 in this example) in Amazon console. The terraform expect a wildcard certificate (*.myproduct.com)
7. Create a Route53 hosted zone for your domain.
8. in `ops/terraform/environments/global`:
Update the `global.tfvars` file with the certificate domain name (*.myproduct.com)
```
terraform init -backend=true -backend-config=$HOME/.aws/terraform
terraform plan -var-file=global.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
terraform apply /tmp/plan.out
```
9. Go to VPC and then subnet in your AWS console. Select one subnet, then to the `Tags` tab and add a tag with "Class": "build". This subnet will be used to build AMIs

# Staging
## First staging AMI

1. In `ops/packer` directory generate the staging base AMI by running:
```
ENVIRONMENT=staging packer build common.json 
```
2. Build the AMI with Elixir and Erlang (You don t want to rebuild erlang each time you build an AMI). Before this, edit elixir.json and replace `[COMMON AMI OWNER]` with the owner id of the AMI you built in step 1. Then run
```
ENVIRONMENT=staging packer build elixir.json 
```
3. Now, let's put our source code in s3 so we can easily find what code is running in production. In `dev` directory run

```
source ./bundle.sh
```
4. Let's put environment specific configuration into myproduct-configuration s3 bucket. You first create a directory named `api` and inside add a file named `my_product-staging.service` with the following content:
```
[Unit]
Description=MyProduct API
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
User=root
Nice=10
ExecStart = /bin/bash -c '/var/lib/my_product/_build/dev/rel/myproduct/bin/myproduct foreground'
ExecStop= /usr/bin/killall hello_world 
Restart=always

[Install]
WantedBy=default.target
```
5. In the same console go in `ops/packer` directory to build the API ami:
```
MIX_ENV=dev ENVIRONMENT=staging packer build api.json
```

## Create staging environment

1. Generate ssh keys for bastion:
```
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/KP_bastion_staging
cat $HOME/.ssh/KP_bastion_staging.pub
```
Take the return of the last command and replace the value of variable `bastion_public_key` in `ops/terraform/environments/eu-west-1-staging/terraform.tfvars` with it.

2. Generate ssh keys for API:
```
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/KP_api_staging
cat $HOME/.ssh/KP_api_staging.pub
```
Take the return of the last command and replace the value of variable `bastion_public_key` in `ops/terraform/environments/eu-west-1-staging/terraform.tfvars` with it.

3. Generate API public key from the key pair:

```
chmod 600 $HOME/.ssh/KP_api_staging.pem
ssh-keygen -y -f $HOME/.ssh/KP_api_staging.pem
```
Take the return of the last command and replace the value of variable `api_public_key` in `ops/terraform/environments/eu-west-1-staging/terraform.tfvars` with it.

4. In `ops/terraform/environments/eu-west-1-staging` edit the `terraform.tfvars` file to specify `bastion_ingress_cidr` and `api_ingress_cidr`. Both are array of CIDR and should contain the cidrs allowed to acccess your bastion for the `bastion_incress_cidr` and your API for the `api_ingress_cidr`.
5. 
6. Now go in `ops/terraform/environments/eu-west-1-staging` and run 
```
terraform init -backend=true -backend-config=$HOME/.aws/terraform
terraform plan -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
terraform apply "/tmp/plan.out"
```
If you have an error message like this one at the end of the latest command:
```
Error: Provider produced inconsistent final plan
 
When expanding the plan for module.deploy.aws_autoscaling_group.api_asg to
include new values learned so far during apply, provider "aws" produced an
invalid new value for .availability_zones: was known, but now unknown.
  
This is a bug in the provider, which should be reported in the provider's own
issue tracker.
```
Run the plan and apply command again:
```
terraform plan -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
terraform apply "/tmp/plan.out"
```
6. You can now test your api going to `https://api-staging.myproduct.com/hello`. (replace `myproduct.com` by the domain name you bought)

## Deploy staging

To deploy staging you need to package the new source code:
```
cd dev
source bundle.sh
```

Then create an AMI with it:
```
cd ../ops/packer
MIX_ENV=dev ENVIRONMENT=staging packer build api.json
```

Then update terraform configuration to deploy the new version:
```
cd ../terraform/environments/eu-west-1-staging/
echo $VERSION
vim api_version.tfvars # update api version
```

And finally deploy new instances:
```
terraform plan -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
```
Ensure it looks ok to you. If it does just run
```
terraform apply "/tmp/plan.out"
```

# Production

## First production AMI

1. In `ops/packer` directory generate the staging base AMI by running:
```
ENVIRONMENT=production packer build common.json 
```
2. Build the AMI with Elixir and Erlang (You don t want to rebuild erlang each time you build an AMI). Before this, edit elixir.json and replace `[COMMON AMI OWNER]` with the owner id of the AMI you built in step 1. Then run
```
ENVIRONMENT=production packer build elixir.json 
```
3. Now, let's put our source code in s3 so we can easily find what code is running in production. In `dev` directory run

```
source ./bundle.sh
```
4. Let's put environment specific configuration into myproduct-configuration s3 bucket. You first create a directory named `api` and inside add a file named `my_product-production.service` with the following content:
```
[Unit]
Description=MyProduct API
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
User=root
Nice=10
ExecStart = /bin/bash -c '/var/lib/my_product/_build/prod/rel/myproduct/bin/myproduct foreground'
ExecStop= /usr/bin/killall hello_world 
Restart=always

[Install]
WantedBy=default.target
```
5. In the same console go in `ops/packer` directory to build the API ami:
```
MIX_ENV=prod ENVIRONMENT=production packer build api.json
```

## Create production environment

1. Generate ssh keys for bastion:
```
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/KP_bastion_production
cat $HOME/.ssh/KP_bastion_production.pub
```
Take the return of the last command and replace the value of variable `bastion_public_key` in `ops/terraform/environments/eu-west-1-prod/terraform.tfvars` with it.

2. Generate ssh keys for API:
```
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/KP_api_production
cat $HOME/.ssh/KP_api_production.pub
```
Take the return of the last command and replace the value of variable `bastion_public_key` in `ops/terraform/environments/eu-west-1-prod/terraform.tfvars` with it.

3. Generate API public key from the key pair:
```
chmod 600 $HOME/.ssh/KP_api_production.pem
ssh-keygen -y -f $HOME/.ssh/KP_api_production.pem
```
Take the return of the last command and replace the value of variable `api_public_key` in `ops/terraform/environments/eu-west-1-prod/terraform.tfvars` with it.

4. In `ops/terraform/environments/eu-west-1-prod` edit the `terraform.tfvars` file to specify `bastion_ingress_cidr` and `api_ingress_cidr`. Both are array of CIDR and should contain the cidrs allowed to acccess your bastion for the `bastion_incress_cidr` and your API for the `api_ingress_cidr`.
5. Run `echo $VERSION` and update `ops/terraform/environments/eu-west-1-prod/api_version.tfvars` with the value returned. 
6. Now go in `ops/terraform/environments/eu-west-1-prod` and run 
```
terraform init -backend=true -backend-config=$HOME/.aws/terraform
terraform plan -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
terraform apply "/tmp/plan.out"
```
If you have an error message like this one at the end of the latest command:
```
Error: Provider produced inconsistent final plan
 
When expanding the plan for module.deploy.aws_autoscaling_group.api_asg to
include new values learned so far during apply, provider "aws" produced an
invalid new value for .availability_zones: was known, but now unknown.
  
This is a bug in the provider, which should be reported in the provider's own
issue tracker.
```
Run the plan and apply command again:
```
terraform plan -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
terraform apply "/tmp/plan.out"
```
7. The pattern used is the blue/green deployment. So production deploy will only brings up an ASG with your new version. Once you are confortable exposing it to the public, you need to go into AWS console to edit your ASG and associate it with the `prod-api` target group.
8. You can now test your api going to `https://api-prod.myproduct.com/hello`. (replace `myproduct.com` by the domain name you bought)

## Deploy production

To deploy staging you need to package the new source code:
```
git tag xxxYOUR NEW VERSION HERE
cd dev
source bundle.sh
```

Then create an AMI with it:
```
cd ../ops/packer
MIX_ENV=prod ENVIRONMENT=production packer build api.json
```
Then update the API version in terraform configuration. If Green is currently running in production, you update the Blue version, if the Blue version is currently running in production, you update the Green version.
```
cd ../terraform/environments/eu-west-1-prod/
echo $VERSION
vim api_version.tfvars # update the version with the content of $VERSION
```
And finally deploy new instances:
```
terraform plan -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform -out /tmp/plan.out
```
It should update the green or blue auto scaling group with the new ami.
Ensure it looks ok to you. If it does just run
```
terraform apply "/tmp/plan.out"
```
You now need to check that everything looks right before exposing it to public traffic. To expose it to public traffic you need to manually edit the new ASG in AWS console to associate it to the `api-prod` target group.

If everything still looks fine, you can set the number of instances of the previous ASG to 0 so you only have the new version exposed to public traffic.

# Tear down an environment

For staging just run the following from the `ops/terraform/environments/eu-west-1-staging/` directory
```
terraform destroy -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform
```

For production just run the following from the `ops/terraform/environments/eu-west-1-prod/` directory
```
terraform destroy -var-file=terraform.tfvars -var-file=api_version.tfvars -var-file=$HOME/.aws/terraform
```


