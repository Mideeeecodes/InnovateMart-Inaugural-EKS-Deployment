output "password" {
  value = aws_iam_user_login_profile.developer.encrypted_password
}