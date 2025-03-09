#
# GitHub OIDC Provider
#

data "aws_iam_openid_connect_provider" "github" {
  arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

#
# Boundary Policy
#

data "aws_iam_policy" "boundary" {
  count = var.boundary_policy ? 1 : 0
  name = local.boundary_policy_name
}

#
# GitHub Actions Role
#

resource "aws_iam_role" "hub" {
  name                  = local.oidc_hub_role_name
  description           = "used by ${var.origin} github actions"
  assume_role_policy    = data.aws_iam_policy_document.trust.json
  force_detach_policies = true
}

data "aws_iam_policy_document" "trust" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        local.oidc_subject_claim
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "github" {
  role       = aws_iam_role.hub.name
  policy_arn = aws_iam_policy.hub.arn
}

#
# GitHub Actions Policy
#

resource "aws_iam_policy" "hub" {
  name        = "${local.oidc_hub_role_name}-policy"
  description = "used by ${var.origin} github actions"
  policy      = data.aws_iam_policy_document.hub.json
}

data "aws_iam_policy_document" "hub" {
  statement {
    sid    = "AllowEcrRegistryRead"
    effect = "Allow"
    actions = [
      "ecr:List*",
      "ecr:Describe*",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEcrRepositoryWrite"
    effect = "Allow"
    actions = [
      "ecr:*",
    ]
    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${local.repository_wildcard}"
    ]
  }
}
