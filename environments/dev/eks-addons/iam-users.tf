# Environment-specific dev IAM users & roles
resource "aws_iam_user" "dev_namespaced_users" {
  for_each = var.aws_namespaced_user_name
  name     = "aws_namespaced_user_name_${each.key}"
}

resource "aws_iam_user" "dev_user" {
  name = "dev_user"
}

resource "aws_iam_role" "dev_namespaced_role" {
  name = "${var.cluster_name}-dev-namespaced-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [for user in aws_iam_user.dev_namespaced_users : user.arn]
        }
      }
    ]
  })
}

resource "aws_iam_role" "dev_user_role" {
  name = "${var.cluster_name}-dev-user-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.dev_user.arn
        }
      }
    ]
  })
}

resource "aws_iam_user_policy" "dev_namespaced_users_policy" {
  for_each = var.aws_namespaced_user_name
  name     = "allow-assume-dev-namespaced-user-${each.key}-policy"
  user     = aws_iam_user.dev_namespaced_users[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dev_namespaced_role.arn
      },
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = local.cluster_access.cluster_arn
      }
    ]
  })
}

resource "aws_iam_user_policy" "dev_user_policy" {
  name = "allow-assume-and-describe-cluster"
  user = aws_iam_user.dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dev_user_role.arn
      },
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = local.cluster_access.cluster_arn
      }
    ]
  })
}
