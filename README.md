# AWS Setup Template

This repository is a template you can use and adapt to start you next project in AWS with automation. It uses Packer and Ansible to build your AMIs and then terraform to deploy them along with the rest of the infrastructure.

![](doc/AWS_template.png?raw=true)

## Table of Contents
1. [Terraform](#terraform)
	1. [Global environment](#global-environment)
	2. [Staging environment](#staging-environment)
	3. [Production environment](#production-environment)
2. [Ansible](#ansible)
	1. [Common role](#common-role)
	2. [Elixir role](#elixir-role)
	3. [API role](#api-role)
3. [Packer](#packer)
4. [Detailed setup](#detailed-setup-rocket)
5. [What is missing?](#what-is-missing)


## Terraform

It has two directories:
* modules where you define the components you want to reuse between environemnts
* environments where you compose modules with specific configuration. There is a special environment which is global. It contains the base needed for all environment.

Each environment uses terraform remote state with S3 as provider. It is useful as the state is shared by every developer so your local state is always up-to-date. It also uses a dynamodb table you need to create manually before hand to store a lock and avoid conflicts and concurrent modifications.

### Global environment

In the example, the global environment contains your route53 zone, SSL certificate, Packer Role and an S3 bucket to store your releases.

### Staging environment

It contains the network configuration which implements an [AWS recommended architecture](https://docs.aws.amazon.com/quickstart/latest/vpc/architecture.html) with support for IPv4 and IPv6. It also creates a s3 bucket to store static files. The API module will setup the Application Load Balancer and the Target Group associated. It will also ensure redis and the security group used by the API. The deploy module will take care of deploying the new API version.

### Production environment

The production environment illustrate how to implement a [blue/green deployment](https://www.martinfowler.com/bliki/BlueGreenDeployment.html) with no downtime. However, the automation is not 100% as *you* need to decide if the deployed version is good enough to proceed or if you should rollback. When you deploy, you need to manually edit the autoscaling group so it registeres its instances in the Target group. You now have the two versions running at the same time. If everything looks
good you can de-register the oldest autoscaling group from the target group and finally remove its instances.

## Ansible

It is used by Packer to install the required software and system configuration.

### Common role

This role setup the base AMI.
* It tunes TCP to disconnect quickly if the connection is interrupted. This is the recommended TCP configuration to integrate with AWS Aurora.
* Increase the max number of openned files as API are mostly IO bound and each TCP connection is an open file descriptor.
* Some python tooling to help doing further setup
* NTP
* A user to run processes
* Authorized keys from github handles.

### Elixir role

It installs Erlang and Elixir

### API role

* It downloads the source code, configurations and secrets from S3.
* It compiles and installs from the source as Elixir compilation is platform dependant :/
* Ensure the process is started when the instance starts


## Packer

Packer defines 3 level of AMIs:
* a common which is based on the latest ubuntu18 AMI from AWS. It installs Ansible common role
* an elixir AMI which install elixir and erlang on top of the common AMI
* an API AMI which compiles and install the code downloaded from S3.

## Detailed setup :rocket:

If you want to give it a try and start hacking it, you can follow the [INSTALL.md](doc/INSTALL.md) automated checklist :D 

## What is missing?

1. Roles have no network restriction which is security hole as you can get some temporary credentials from the instance calling [http://169.254.169.254/iam/security-credentials/API-Role](http://169.254.169.254/iam/security-credentials/API-Role) and use them from your computer.
2. Manage authorized keys in bastion and api using S3. It can be achieved adapting the [user-data.sh](https://github.com/terraform-community-modules/tf_aws_bastion_s3_keys/blob/master/user_data.sh) from the terraform community plugin [tf_aws_bastion_s3_keys](https://github.com/terraform-community-modules/tf_aws_bastion_s3_keys)
3. Make the bastion temporary and on-demand instead of always having an instance up and running for security and money reason.
4. Add [fail2ban](https://github.com/fail2ban/fail2ban) to bastion
