locals {
  this_application = ["Spark"]
}

# Create new EC2 key pair
resource "tls_private_key" "emr_private_key" {
  algorithm = "RSA"
}

module "emr_key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  version    = "1.0.0"
  key_name   = "spark-test-emr-key"
  public_key = tls_private_key.emr_private_key.public_key_openssh
  tags       = var.tags
}

# EMR Static Spark cluster
module "emr-spark" {
  # source = "git::git@github.com:Datatamer/terraform-aws-emr.git?ref=7.3.2"
  source = "../.."

  # Configurations
  create_static_cluster  = true
  release_label          = "emr-5.29.0" # spark 2.4.4
  applications           = local.this_application
  emr_config_file_path   = "../emr-config-template.json"
  tags                   = var.tags
  abac_valid_tags        = var.abac_valid_tags
  security_configuration = aws_emr_security_configuration.secconfig.name

  bootstrap_actions = [
    {
      name = "cw_agent_install",
      path = "s3://${module.emr-rootdir-bucket.bucket_name}/${aws_s3_bucket_object.sample_bootstrap_script.id}"
      args = []
    }
  ]

  # Networking
  subnet_id = var.compute_subnet_id
  vpc_id    = var.vpc_id

  # External resource references
  bucket_name_for_root_directory = module.emr-rootdir-bucket.bucket_name
  bucket_name_for_logs           = module.emr-logs-bucket.bucket_name
  additional_policy_arns = [module.emr-logs-bucket.rw_policy_arn,
    module.emr-rootdir-bucket.rw_policy_arn,
    aws_iam_policy.emr_service_policy_for_kms.arn,
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
  bucket_path_to_logs = "logs/spark-test-cluster/"
  key_pair_name       = module.emr_key_pair.key_pair_key_name

  # Names
  cluster_name                  = format("%s-%s", var.name_prefix, "Spark-Test-EMR-Cluster")
  emr_service_role_name         = format("%s-%s", var.name_prefix, "spark-test-service-role")
  emr_ec2_role_name             = format("%s-%s", var.name_prefix, "spark-test-ec2-role")
  emr_ec2_instance_profile_name = format("%s-%s", var.name_prefix, "spark-test-instance-profile")
  emr_service_iam_policy_name   = format("%s-%s", var.name_prefix, "spark-test-service-policy")
  emr_ec2_iam_policy_name       = format("%s-%s", var.name_prefix, "spark-test-ec2-policy")
  master_instance_fleet_name    = format("%s-%s", var.name_prefix, "Spark-Test-MasterInstanceFleet")
  core_instance_fleet_name      = format("%s-%s", var.name_prefix, "Spark-Test-CoreInstanceFleet")
  emr_managed_master_sg_name    = format("%s-%s", var.name_prefix, "Spark-Test-EMR-Spark-Master")
  emr_managed_core_sg_name      = format("%s-%s", var.name_prefix, "Spark-Test-EMR-Spark-Core")
  emr_service_access_sg_name    = format("%s-%s", var.name_prefix, "Spark-Test-EMR-Spark-Service-Access")

  # Scale
  master_instance_on_demand_count = 1
  core_instance_on_demand_count   = 2
  master_instance_type            = "m4.large"
  core_instance_type              = "r5.xlarge"
  master_ebs_size                 = 50
  core_ebs_size                   = 50

  # Security Group IDs
  emr_managed_master_sg_ids = module.aws-emr-sg-master.security_group_ids
  emr_managed_core_sg_ids   = module.aws-emr-sg-core.security_group_ids
  emr_service_access_sg_ids = module.aws-emr-sg-service-access.security_group_ids
}

resource "aws_emr_security_configuration" "secconfig" {
  depends_on    = [resource.aws_kms_key.kms_encryption_key]
  name          = format("%s-%s", var.name_prefix, "security-configuration")
  configuration = <<EOF
  {
  "EncryptionConfiguration": {
        "EnableInTransitEncryption": ${var.enable_in_transit_encryption},
        "EnableAtRestEncryption": ${var.enable_at_rest_encryption},
        "InTransitEncryptionConfiguration": {
			       "TLSCertificateConfiguration": {
				       "CertificateProviderType": "PEM",
				       "S3Object": "${var.s3_pem_file_location}"
			                                      }
	                                        	},
        "AtRestEncryptionConfiguration": {
                "LocalDiskEncryptionConfiguration": {
                "EnableEbsEncryption": ${var.enable_ebs_encryption},
                "EncryptionKeyProviderType": "AwsKms",
                "AwsKmsKey": "${local.effective_kms_key_arn}"
                                               }
                                               }
     }    }
EOF
}
