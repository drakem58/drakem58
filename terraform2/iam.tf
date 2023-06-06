resource "aws_iam_policy" "policy" {
  name        = "${var.env}_policy"
  description = "${var.env} group policy"
  policy      = var.policy
}

resource "aws_iam_group" "iamgroup" {
  name = "${var.env}_group"
}

resource "aws_iam_group_membership" "membership" {
  name = "${var.env}_membership"

  users = [
    aws_iam_user.user.name,
  ]
  group = aws_iam_group.iamgroup.name
}

resource "aws_iam_user" "user" {
  name = "${var.env}_user"
}

resource "aws_iam_policy_attachment" "policyattachment" {
  name       = "${var.env}_policyattachment1"
  groups     = [aws_iam_group.iamgroup.name]
  policy_arn = aws_iam_policy.policy.arn
}
