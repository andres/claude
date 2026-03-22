#!/bin/bash
set -e

AWS_ACCOUNT="077522587842"
AWS_REGION="us-west-1"
ECR_BASE="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
DO_REGISTRY="registry.emrbear.com"

echo ">>> Pulling:  $DO_REGISTRY/bear5:master"
docker pull "$DO_REGISTRY/bear5:master"

echo ">>> Tagging:  $ECR_BASE/bear5:master"
docker tag "$DO_REGISTRY/bear5:master" "$ECR_BASE/bear5:master"

echo ">>> Pushing:  $ECR_BASE/bear5:master"
docker push "$ECR_BASE/bear5:master"

echo ">>> Done!"
