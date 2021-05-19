#!/usr/bin/env bash

#configure git
if [ ! -z "$GH_TOKEN" ]; then
  git config --global url."https://foo:${GH_TOKEN}@github.com/".insteadOf "https://github.com/"
fi

#fail if any of the following fail.
set -e

/tmp/tfenv/bin/tfenv install min-required
/tmp/tfenv/bin/tfenv use min-required
/tmp/tfenv/bin/terraform fmt -check -recursive -diff
/tmp/tfenv/bin/terraform init
/tmp/tfenv/bin/terraform validate
