# Tamr AWS EMR Security Groups Terraform Module
This terraform module creates all the security groups and rules required for an AWS EMR cluster.

# Examples
## Basic
Inline example implementation of the module.  This is the most basic example of what it would look like to use this module.
```
module "emr_security_groups" {
  source = "git::git@github.com:Datatamer/terraform-aws-emr.git//modules/aws-emr-sgs?ref=x.y.z"

  vpc_id                    = "vpc-examplevpcid"
  emr_service_access_sg_ids = ["sg-1234567890"]
}
```
## Minimal
This example directly invokes this submodule.
- [Ephemeral Spark Example](https://github.com/Datatamer/terraform-aws-emr/tree/master/examples/ephemeral-spark)


# Resources created
This terraform module creates:
* 1 Security Group
* variable Security Group Rules

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 2.45.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.45.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| emr\_service\_access\_sg\_ids | List of EMR service access security group ids | `list(string)` | n/a | yes |
| vpc\_id | VPC ID of the network | `string` | n/a | yes |
| emr\_managed\_sg\_name | Name for the EMR managed security group | `string` | `"TAMR-EMR-Internal"` | no |
| tags | A map of tags to add to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| emr\_managed\_sg\_id | Security group id of the EMR Managed Security Group |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

# Reference documents:
* AWS EMR Security Groups: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-man-sec-groups.html
* AWS EMR Additional Security Groups: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-sg-specify.html
* Terraform module structure: https://www.terraform.io/docs/modules/index.html#standard-module-structure
