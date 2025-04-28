#
# GitHub OIDC Provider
#

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

#
# GitHub Actions Role
#

resource "aws_iam_role" "integration" {
  name                  = var.topology.resource.integration_account_role_name
  description           = "used by ${var.topology.git.origin} github actions"
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
        var.topology.oidc_subject_claim
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "github" {
  role       = aws_iam_role.integration.name
  policy_arn = aws_iam_policy.integration.arn
}

#
# GitHub Actions Policy
#

resource "aws_iam_policy" "integration" {
  name        = "${var.topology.resource.integration_account_role_name}-policy"
  description = "used by ${var.topology.git.origin} github actions"
  policy      = data.aws_iam_policy_document.integration.json
}

data "aws_iam_policy_document" "integration" {
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
      "arn:aws:ecr:*:${var.topology.integration_account_id}:repository/${var.topology.resource.image_path_wildcard}"
    ]
  }
}
