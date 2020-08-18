resource "aws_eks_node_group" "managed_workers_a" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.environment_name}-workers-${var.availability_zones[count.index]}"
  node_role_arn   = aws_iam_role.managed_workers.arn
  subnet_ids      = [module.vpc.private_subnets[count.index]]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  instance_types = [var.node_pool_instance_type]
  ami_type       = "AL2_ARM_64"
  labels = {
    lifecycle = "OnDemand"
    az        = var.availability_zones[count.index]
  }

  remote_access {
    ec2_ssh_key               = aws_key_pair.generated_key.key_name
    source_security_group_ids = [aws_security_group.provisioner.id]
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    create_before_destroy = true
  }

  count = length(var.availability_zones)
}