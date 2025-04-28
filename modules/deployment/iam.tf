locals {
  boundary_policy_arn = length(aws_iam_policy.boundary) > 0 ? aws_iam_policy.boundary[0].arn : null
}

#
# GitHub OIDC Provider
#

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

#
# Boundary Policy
#

resource "aws_iam_policy" "boundary" {
  count       = var.topology.resource.enable_boundary_policy ? 1 : 0
  name        = var.topology.resource.boundary_policy_name
  description = "permission boundary for roles created by ${var.topology.git.origin} github actions"
  policy      = var.boundary_policy_document.json
}

#
# Secondary Policy
#

resource "aws_iam_policy" "extended" {
  count       = var.oidc_policy_document != null ? 1 : 0
  name        = "${var.topology.oidc.deployment_role_name}-policy-extended"
  description = "additional policy for ${var.topology.git.origin} github actions"
  policy      = var.oidc_policy_document.json
}

resource "aws_iam_role_policy_attachment" "extended" {
  count      = var.oidc_policy_document != null ? 1 : 0
  role       = aws_iam_role.deployment.name
  policy_arn = aws_iam_policy.extended[0].arn
}

#
# GitHub Actions Role
#

resource "aws_iam_role" "deployment" {
  name                  = var.topology.oidc.deployment_role_name
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
        var.topology.oidc.subject_claim
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "github" {
  role       = aws_iam_role.deployment.name
  policy_arn = aws_iam_policy.deployment.arn
}

#
# GitHub Actions Policy
#

resource "aws_iam_policy" "deployment" {
  name        = "${var.topology.oidc.deployment_role_name}-policy"
  description = "used by ${var.topology.git.origin} github actions"
  policy      = data.aws_iam_policy_document.deployment.json
}

data "aws_iam_policy_document" "deployment" {
  statement {
    sid    = "AllowEcrRegistryLogin"
    effect = "Allow"
    actions = [
      "ecr:DescribeRegistry",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEcrLambda"
    effect = "Allow"
    actions = [
      "ecr:SetRepositoryPolicy",
      "ecr:GetRepositoryPolicy",
    ]

    resources = [
      "arn:aws:ecr:*:${local.account_id}:repository/${var.topology.resource.image_path_wildcard}"
    ]
  }

  statement {
    // DENY the OIDC role the ability to assume the roles it creates.
    sid    = "DenyOIDCChaining"
    effect = "Deny"
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.topology.resource.enable_boundary_policy ? [1] : []
    content {
      sid    = "DenyBoundaryPolicyDeletion"
      effect = "Deny"
      actions = [
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion"
      ]
      resources = [
        local.boundary_policy_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.topology.resource.enable_boundary_policy ? [1] : []
    content {
      sid       = "DenyRoleCreateWithoutBoundary"
      effect    = "Deny"
      actions   = ["iam:CreateRole"]
      resources = ["arn:aws:iam::${local.account_id}:role/${var.topology.resource.resource_name_wildcard}"]
      condition {
        test     = "StringNotEquals"
        variable = "iam:PermissionsBoundary"
        values   = [local.boundary_policy_arn]
      }
    }
  }

  statement {
    sid    = "AllowEniRoleWrite"
    effect = "Allow"
    actions = [
      "iam:*"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/AWSLambdaVPCAccessExecutionRole",
      "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    ]
  }

  statement {
    sid    = "AllowIamWrite"
    effect = "Allow"
    actions = [
      "iam:*"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:policy/${var.topology.resource.resource_name_wildcard}",
      "arn:aws:iam::${local.account_id}:role/${var.topology.resource.resource_name_wildcard}",
    ]
  }



  statement {
    sid    = "AllowLambdaWrite"
    effect = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = [
      "arn:aws:lambda:*:${local.account_id}:function:${var.topology.resource.resource_name_wildcard}",
    ]
  }

  statement {
    sid    = "AllowApiGatewayV2Read"
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
      for id in var.api_gateway_ids : [
        "arn:aws:apigateway:*::/apis/${id}",
        "arn:aws:apigateway:*::/apis/${id}/*",
        "arn:aws:apigateway:*::/tags/${id}",
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
      "arn:aws:logs:*:${local.account_id}:log-group:/aws/lambda/${var.topology.resource.resource_path_wildcard}",
      "arn:aws:logs:*:${local.account_id}:log-group:/aws/lambda/${var.topology.resource.resource_path_wildcard}:*",
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
      "arn:aws:events:*:${local.account_id}:rule/${var.topology.resource.resource_name_wildcard}"
    ]
  }

  statement {
    sid = "AllowVPCRead"
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }
}
