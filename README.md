# github-actions


Usage information: https://vfs.atlassian.net/wiki/spaces/OT/pages/1474595275/Slack+Notifications+from+Github+Actions

Support: https://depo-platform-documentation.scrollhelp.site/support/Getting-help-from-the-Platform-in-Slack.1439138197.html

## Requirements

These actions do require that the AWS OIDC Provider role is configured for your target repository.

At the time of publishing these reusable actions only use the *prt-gha-oidc-role* role.

## Standard Actions

To use these standard actions, create the following actions in your *.github/workflows/* directory within your repository.

### Push

On every push build and publish docker images and/or helm charts...  The standard pipeline builds a docker image *if* the Dockerfile exists in the root of the repository.  The image will be published to AWS ECR with a tag relating to your branch, SHA and version.

* Image publish Standard: dsva/\<github-repo-name\>:\<version\>
* Helm Chart publish Standard: dsva/helm/\<github-repo-name\>:\<version\>

**Example Code**

```yaml
name: "Build And Publish"
run-name: "Build And Publish"

on: [push]

jobs:
  deploy-job:
    uses: department-of-veterans-affairs/vsp-github-actions/.github/workflows/build-and-publish.yaml@main
    secrets: inherit
```

### Pull Request

On every pull request event deploy all environments run a plan on every environment specified in the cicd.yaml file at the root of your directory.  This only runs if you have a terrform directory at the root of your repository.  This action leverages terraform workspaces which are based on the environment name.  The output of TF Init, Lint and the plan for each environment will be added as a comment to your pull request.

**Example Code**

```yaml
name: "Comment a Plan on a PR"
run-name: "Comment a Plan on a PR"

on: [pull_request]

jobs:
  pr-tf-plan:
    uses: department-of-veterans-affairs/vsp-github-actions/.github/workflows/tf-plan.yaml@main
    secrets: inherit
```

### Tag

On every tag event plan all environments.  If all plans are successful.  Deploy all environments in the order specified in the cicd.yaml file in your repo.

**Example Code**

```yaml
name: "Deploy Environments"
run-name: "Deploy Environments"

on:
  workflow_dispatch:
  repository_dispatch:
    types: [trigger-workflow]
  
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
      - '[0-9]+.[0-9]+.[0-9]+'

jobs:
  Deploy-Envs:
    uses: department-of-veterans-affairs/vsp-github-actions/.github/workflows/deploy-all.yaml@main
    secrets: inherit
```

or on publish events...

```yaml
name: "Deploy Environments"
run-name: "Deploy Environments"

on:
  release:
    types: [published]

jobs:
  Deploy-Envs:
    uses: department-of-veterans-affairs/vsp-github-actions/.github/workflows/deploy-all.yaml@main
    secrets: inherit
```

and / or on a schedule trigger deploy from the default branch...

```yaml
name: "Deploy Environments"
run-name: "Deploy Environments"

on:
  schedule:
    - cron: "0 13 * * *" 

jobs:
  Deploy-Envs:
    uses: department-of-veterans-affairs/vsp-github-actions/.github/workflows/deploy-all.yaml@main
    secrets: inherit
```


## Example cicd.yaml

```yaml
environments:
  - sandbox
  - dev
  - staging
  - production
```

## Deployment Conventions

### Terraform

The main terraform module **Must** contain a variable of type string named *environment*.  This will be set at the time of execution.

```hcl
variable "environment" {
  type = string
}
```

## Future

### Deployments

On every deployment event trigger the standard deploy notifier and dora metrics analyzer.

**Example Code**

```yaml
name: "Deploy Event"
run-name: "Deploy Event"

on:
  deployment

jobs:
  Deploy-Envs:
    uses: department-of-veterans-affairs/vsp-github-actions/.github/workflows/deploy-event.yaml@main
    secrets: inherit
```

### Preview / Review Environments

Future...

