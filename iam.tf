resource "aws_iam_user" "developer" {
  name = "dev-altsch"
  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

data "aws_iam_policy_document" "readonly" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*", "eks:List*", "eks:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "policy" {
  name   = "developer"
  user   = aws_iam_user.developer.name
  policy = data.aws_iam_policy_document.readonly.json
}


resource "aws_iam_user_login_profile" "developer" {
  user    = aws_iam_user.developer.name
#   pgp_key = "keybase:developer"
}

resource "aws_eks_access_policy_association" "developer-eks-access" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"
  principal_arn = aws_iam_user.developer.arn

  access_scope {
    type       = "namespace"
    namespaces = ["default"]
  }
}

