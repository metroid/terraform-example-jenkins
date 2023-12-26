# Recursos eks
#  * cluster development
#  * cluster deployment
#  * 
#
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.23"
  subnets         = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id


  workers_group_defaults = {
    root_volume_type = "gp3"
    
  }

  worker_groups = [
    {
      name                          = var.workers_name_deployment
      instance_type                 = var.instance_type
      additional_userdata           = ""
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
      
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
 
 resource "aws_eks_cluster" "development_cluster" {
  name     = "development-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
    # Más configuraciones según sea necesario
  }

  # Otros ajustes del clúster...

}


resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.development_cluster.name
  node_group_name = "dev-group-node"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = module.vpc.private_subnets
labels = {
  Name = "w-node"
}
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
   update_config {
    max_unavailable = 1
    
  }
  # Opciones adicionales como AMI, etiquetas, etc.
  # ...
    depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  
}

# Adjuntar las políticas de IAM necesarias para los nodos de EKS
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}
