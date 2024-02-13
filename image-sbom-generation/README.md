# SBOM Generation

This action generates an sbom json file using the following action:

`aquasecurity/trivy-action`

It then uploads the file to the desired S3 bucket where it can then be queried by Athena.

`.github/workflows/sbom-generation.yml`

The formatting of the SBOM json file is CyloneDX. For more information - https://cyclonedx.org/

## Inputs

### `image_name`
**Required** The image name - this will be used as part of the sbom file naming

### `image_tag`
**Required** The image tag - this will be used as part of the sbom file naming

### `ecr_repo_name`
**Required** the name of the desire ECR repo

### `output_bucket`
**Required**  The S3 URI of the bucket that will be used to store the sbom file(s)
