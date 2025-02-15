provider "aws" {
  profile = var.TF_PROFILE
  region  = "eu-west-2"
}

provider "vault" {
  address = var.VAULT_ADDR
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}