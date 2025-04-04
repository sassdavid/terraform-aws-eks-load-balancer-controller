locals {
  eks_pod_identity_role_create = var.enabled && var.service_account_create && var.eks_pod_identity_role_create
}

resource "aws_iam_policy" "eks_pod_identity" {
  count       = local.eks_pod_identity_role_create && var.eks_pod_identity_policy_enabled ? 1 : 0
  name        = "${var.eks_pod_identity_role_name_prefix}-${var.helm_release_name}"
  path        = "/"
  description = "Policy for aws-load-balancer-controller service"

  policy = data.aws_iam_policy_document.this[0].json
  tags   = var.eks_pod_identity_tags
}

data "aws_iam_policy_document" "eks_pod_identity_assume" {
  count = local.eks_pod_identity_role_create ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "eks_pod_identity" {
  count = local.eks_pod_identity_role_create ? 1 : 0

  name               = "${var.eks_pod_identity_role_name_prefix}-${var.helm_release_name}"
  assume_role_policy = data.aws_iam_policy_document.eks_pod_identity_assume[0].json

  tags = var.eks_pod_identity_tags
}

resource "aws_iam_role_policy_attachment" "eks_pod_identity" {
  count = local.eks_pod_identity_role_create ? 1 : 0

  role       = aws_iam_role.eks_pod_identity[0].name
  policy_arn = aws_iam_policy.eks_pod_identity[0].arn
}

resource "aws_eks_pod_identity_association" "this" {
  count = local.eks_pod_identity_role_create ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.eks_pod_identity[0].arn
}
