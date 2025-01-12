data "vault_generic_secret" "gitlab_private_key" {
  path = "secret/gitlab_keys"
}

data "vault_generic_secret" "gitlab_public_key" {
  path = "secret/gitlab_keys"
}

data "vault_generic_secret" "ec2_ssh_public_key" {
  path = "secret/ec2_ssh"
}

data "vault_generic_secret" "db_credentials" {
  path = "secret/db_credentials"
}

data "vault_generic_secret" "nat_ssh_private_key" {
  path = "secret/ec2_ssh"
}