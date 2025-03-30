provider "aws" {
  profile = var.TF_PROFILE
  region  = "eu-central-1"
}

provider "vault" {
  address = var.VAULT_ADDR
  token   = var.VAULT_TOKEN
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

