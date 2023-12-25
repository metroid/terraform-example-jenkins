# Recursos eks
#  * cluster development
#  * cluster deployment
#  * 
#
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.22"
  subnets         = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp3"
  }

  worker_groups = [
    {
      name                          = var.workers_name_development
      instance_type                 = var.instance_type
      additional_userdata           = ""
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      asg_desired_capacity          = 2
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks_deploy" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = local.cluster_name_dep
  cluster_version = "1.22"
  subnets         = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp3"
  }

  worker_groups = [
    {
      name                          = var.workers_name_deployment
      user_data       = "${file("install_jenkins.sh")}"
      instance_type                 = var.instance_type
      associate_public_ip_address = true
      key_name        = var.keyname
      additional_userdata           = ""
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
    },
  ]
}