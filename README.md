# ** Notes **

_Project setup_

1. Set up environment variable \
2. Set up Vault \
3. Add secrets \
4. Run terraform


_Vault setup_

1. Run Vault on the machine through "vault server -dev"
2. Open Vault in the browser through the provided link
3. Copy the root token that is provided upon startup and add to the token auth page
4. Locate to secrets and add all Groups/Secrets as per documentation
5. Set vault address to the env variables and re-run environment variable setup script (set-env-vars.sh)


_Variables that need to be set in vault_

1. Group - ec2_ssh \
    1.1. var - ec2_ssh_public_key \
    1.2. var - nat_ssh_private_key \
2. Group - gitlab_keys \
    1.1. var - gitlab_private_key \
    1.2. var - gitlab_public_key \
3. Group - db_credentials \
    1.1. var - username \
    1.2. var - password \


_Testing plan_

1. Functional state:
    1.1. Search for the created bucket/table  \
    1.2. Test by adding the bucket s3 block to the terraform block after it is created and observe state by adding run timers to check if changes are allowed during these timers(changes shouldn't be allowed) \
2. Correctly set FE:
    1.1. Check app functioning in browser
    1.2. SSH for further testing and debugging
    1.2. 
3. Correctly set BE:
    1.1. 
    1.2. 
4. Correct communication:
    1.1. 
    1.2. 
5. Funcctional ECS: 
    1.1. 
    1.2. 
6. Functional RDS: