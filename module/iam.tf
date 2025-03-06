#
# GitHub OIDC Provider
#

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # Hex-encoded SHA-1 hash of the X.509 domain certificate
  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  arn   = "arn:aws:iam::${var.ecr_hub_account_id}:oidc-provider/token.actions.githubusercontent.com"
}

#
# GitHub Actions Role
#

resource "aws_iam_role" "github" {
  name                  = "${local.prefix}-oidc-role"
  description           = "used by ${var.origin} github actions"
  assume_role_policy    = data.aws_iam_policy_document.trust.json
  force_detach_policies = true
}

data "aws_iam_policy_document" "trust" {
  statement {
    principals {
      type        = "Federated"
      identifiers = var.create_oidc_provider ? [aws_iam_openid_connect_provider.github[0].arn] : [data.aws_iam_openid_connect_provider.github[0].arn]
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
        "repo:${local.repo_owner}/${local.repo_name}:${local.allowed_branches}"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "github" {
  role       = aws_iam_role.github.name
  policy_arn = aws_iam_policy.github.arn
}

#
# GitHub Actions Policy
#

resource "aws_iam_policy" "github" {
  name        = "${local.prefix}-oidc-policy"
  description = "used by ${var.origin} github actions"
  policy      = data.aws_iam_policy_document.monad.json
}

data "aws_iam_policy_document" "monad" {
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
      "arn:aws:ecr:${data.aws_region.current.name}:${var.ecr_hub_account_id}:repository/${local.repository_wildcard}"
    ]
  }

  statement {
    sid    = "AllowIAMAccessWrite"
    effect = "Allow"
    actions = [
      "iam:*"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.resource_wildcard}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.resource_wildcard}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSLambdaVPCAccessExecutionRole"
    ]
    # condition {
    #   test     = "StringEquals"
    #   variable = "iam:PermissionsBoundary"
    #   values   = [aws_iam_policy.github_boundary.arn]
    # }
  }

  statement {
    sid    = "AllowLambdaWrite"
    effect = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.resource_wildcard}",
    ]
  }

  statement {
    sid    = "AllowApiGatewayRead"
    effect = "Allow"
    actions = [
      "apigateway:GET"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowApiGatewayV2Write"
    effect = "Allow"
    actions = [
      "apigateway:*"
    ]
    resources = flatten([
      for apigatewayv2_id in var.apigatewayv2_ids : [
        "arn:aws:apigateway:${data.aws_region.current.name}::/apis/${apigatewayv2_id}",
        "arn:aws:apigateway:${data.aws_region.current.name}::/apis/${apigatewayv2_id}/*",
        "arn:aws:apigateway:${data.aws_region.current.name}::/tags/${apigatewayv2_id}",
      ]
    ])
  }

  statement {
    sid    = "AllowCloudWatchWrite"
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.path_wildcard}:*",
    ]
  }

  statement {
    sid    = "AllowEventBridgeRead"
    effect = "Allow"
    actions = [
      "events:List*",
      "events:Describe*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEventBridgeWrite"
    effect = "Allow"
    actions = [
      "events:*"
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/${local.resource_wildcard}"
    ]
  }
}

#
# GitHub Actions Boundary Policy
#

# resource "aws_iam_policy" "github_boundary" {
#   name        = "${var.prefix}-oidc-boundary-policy"
#   description = "used by monad in github actions"
#   policy      = data.aws_iam_policy_document.github_boundary.json
# }

