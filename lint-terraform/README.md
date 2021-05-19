# Lint Terraform Docker action

This action lints a terraform module.
- Uses tfenv to determine what version of terraform to use based on the version required in your module.
- runs `terraform fmt -check -recursive -diff`
- runs `terraform init` to download any dependent modules
- runs `terraform validate`

## Inputs

### `github-token`
**Not Required** A github personal access token with access to the repositories you keep Terraform modules in (if you have private modules)

### `aws_region`
**Required** The AWS region to use for `terraform validate`

## Example usage
```
uses: dginther/github-actions/lint-terraform
with:
  aws_region: "us-east-1"
```
