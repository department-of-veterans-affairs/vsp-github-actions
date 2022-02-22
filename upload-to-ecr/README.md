## Upload to ECR action for the Platform Team

This action will perform the following actions by default:
- Configure AWS Credentials
- Add env vars if needed
- Set up Docker BuildX (for caching builds)
- Build a local docker container from ./Dockerfile 
- Scan the resulting container with Anchore
- Upload resulting vuln scan results to Github
- Log into ECR
- Build (using cache from local build) image and push to ECR
- Install Cosign
- Sign container in ECR
- Create SBOM using Anchore Syft
- Attest SBOM in ECR

The following inputs can be used:  
| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| aws-access-key-id | String | AWS Access Key ID for login to ECR | | Y |
| aws-secret-access-key | String | AWS Secret Access Key for login to ECR | | Y |
| aws-region | String | AWS Region for ECR Repository | "us-gov-west-1" | N |
| github-token-parameter-store-path | String | AWS Parameter Store path to Github Token | | Y |
| env-vars | Bool | Optional, if you are using a .env file | false | N |
| dockerfile | String | PAth to Dockerfile | "{context}/Dockerfile" | N |
| docker-build-args | String | Build Arguments to use when building container | "" | N |
| ecr-repository | String | ECR Repository | | Y |
| aws-kms-key | String | Alias of KMS Key to sign container with | | Y |
| vuln-severity-cutoff | String | Severity to use as a gate for Vuln Scan | critical | N |
| vuln-fails-build | Bool | Failed Scan stops build/push? | false | N |
| image-tag | String | Tag to use for image | ${{ github.sha }} | N |
