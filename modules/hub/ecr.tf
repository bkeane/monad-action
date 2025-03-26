locals {
    account_ids = toset([ for account in var.spoke_accounts : account.id ])
}

resource "aws_ecr_repository" "services" {
    for_each = var.images
    name = each.value
    image_tag_mutability = var.mutable ? "MUTABLE" : "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "cross_account_access" {
    for_each = aws_ecr_repository.services
    repository = each.value.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "CrossAccountPermission"
                Effect = "Allow"
                Principal = {
                    AWS = concat([
                        for id in local.account_ids:
                            "arn:aws:iam::${id}:root"
                    ])
                }
                Action = [
                    "ecr:BatchGetImage",
                    "ecr:GetDownloadUrlForLayer"
                ]
            },
            {
                Sid = "LambdaECRImageRetrievalPolicy"
                Effect = "Allow"
                Action = [
                    "ecr:BatchGetImage",
                    "ecr:GetDownloadUrlForLayer"
                ]
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
                Condition = {
                    StringLike = {
                        "aws:sourceARN": concat([
                            for id in local.account_ids:
                                "arn:aws:lambda:${data.aws_region.current.name}:${id}:function:*"
                        ])
                    }
                }
            }
        ]
    })
}