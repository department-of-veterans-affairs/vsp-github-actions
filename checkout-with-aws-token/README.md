## Checkout With Token From AWS Action

This action will perform the following actions by default:
- Configure AWS Credentials
- Retrieve the specified token from AWS Parameter Store
- Checkout a repository using the token specified
  - With the exception of the `submodules` input, this action uses the defaults of [`actions/checkout`](https://github.com/actions/checkout#usage).

The following inputs can be used:  
| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| aws-access-key-id | String | AWS Access Key ID for login to ECR | | Y |
| aws-region | String | AWS Region for ECR Repository | `"us-gov-west-1"` | N |
| aws-secret-access-key | String | AWS Secret Access Key for login to ECR | | Y |
| github-token-parameter-store-path | String | AWS Parameter Store path to Github Token | | Y |
| path | String | Relative path to checkout the repository | `""` | N |
| ref | String | Branch, tag, or SHA to checkout | Default branch| N |
| repository | String | Repository name with owner | `${{ github.repository }}`| N |
| submodules | String | Whether to checkout submodules | `"recursive"` | N |