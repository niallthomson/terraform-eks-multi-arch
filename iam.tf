resource "aws_iam_role" "managed_workers" {
  name               = "${var.environment_name}-worker-node"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_workers.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_workers.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_workers.name
}

resource "aws_iam_role_policy_attachment" "eks-AWSXRayDaemonWriteAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.managed_workers.name
}

resource "aws_iam_role_policy_attachment" "eks-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.managed_workers.name
}

resource "aws_iam_policy" "eks-AppMesh" {
  name        = "${var.environment_name}-appmesh"
  description = "EKS AppMesh policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "appmesh:*",
        "servicediscovery:CreateService",
        "servicediscovery:DeleteService",
        "servicediscovery:GetService",
        "servicediscovery:GetInstance",
        "servicediscovery:RegisterInstance",
        "servicediscovery:DeregisterInstance",
        "servicediscovery:ListInstances",
        "servicediscovery:ListNamespaces",
        "servicediscovery:ListServices",
        "servicediscovery:GetInstancesHealthStatus",
        "servicediscovery:UpdateInstanceCustomHealthStatus",
        "servicediscovery:GetOperation",
        "route53:GetHealthCheck",
        "route53:CreateHealthCheck",
        "route53:UpdateHealthCheck",
        "route53:ChangeResourceRecordSets",
        "route53:DeleteHealthCheck"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-AppMesh" {
  policy_arn = aws_iam_policy.eks-AppMesh.arn
  role       = aws_iam_role.managed_workers.name
}