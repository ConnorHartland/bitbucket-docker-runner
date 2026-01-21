resource "aws_secretsmanager_secret" "bitbucket_oauth" {
  name        = "bitbucket-runner-oauth"
  description = "OAuth credentials for Bitbucket Pipelines runner"

  tags = {
    Name        = "bitbucket-runner-oauth"
    Environment = var.environment
  }
}

# Note: The secret value should be set manually or via a separate process
# Expected JSON format: {"client_id": "...", "client_secret": "..."}
#
# To set the secret value manually:
# aws secretsmanager put-secret-value \
#   --secret-id bitbucket-runner-oauth \
#   --secret-string '{"client_id":"YOUR_OAUTH_KEY","client_secret":"YOUR_OAUTH_SECRET"}'
