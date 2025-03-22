data "vault_generic_secret" "gitlab_private_key" {
  path = "secret/gitlab_keys"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "gitlab_public_key" {
  path = "secret/gitlab_keys"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "ec2_ssh_public_key" {
  path = "secret/ec2_ssh"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "nat_ssh_private_key" {
  path = "secret/ec2_ssh"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "username" {
  path = "secret/db_credentials"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "password" {
  path = "secret/db_credentials"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "cloudflare_zone_id" {
  path = "secret/cloudflare"
  depends_on = [
    module.vault
  ]
}

data "vault_generic_secret" "cloudflare_api_token" {
  path = "secret/cloudflare"
  depends_on = [
    module.vault
  ]
}