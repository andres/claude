#!/bin/bash
# Step 2: Pull images from DO registry + ghcr.io, push to AWS ECR
# Region: us-west-1, Account: 077522587842

set -e

AWS_ACCOUNT="077522587842"
AWS_REGION="us-west-1"
ECR_BASE="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"

DO_REGISTRY="registry.emrbear.com"
GHCR_REGISTRY="ghcr.io/emrbear"

# --- Login to all registries ---

echo "=== Logging into registries ==="

# DO registry
echo "Logging into $DO_REGISTRY..."
echo "assyrian-bliss-trauma-collard-pluto-initiate-back" | docker login "$DO_REGISTRY" -u emrbear --password-stdin

# ghcr.io (already logged in, but ensure)
echo "Logging into ghcr.io..."
gh auth token | docker login ghcr.io -u andres --password-stdin

# AWS ECR
echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_BASE"

echo ""

# --- Helper function ---
migrate() {
  local SRC="$1"
  local DST="$2"

  echo ""
  echo ">>> Pulling:  $SRC"
  if docker pull "$SRC"; then
    echo ">>> Tagging:  $DST"
    docker tag "$SRC" "$DST"
    echo ">>> Pushing:  $DST"
    docker push "$DST"
    echo ">>> Done:     $DST"
  else
    echo "!!! FAILED to pull: $SRC — skipping"
  fi
}

# =============================================
#  FROM registry.emrbear.com → ECR
# =============================================
echo ""
echo "============================================"
echo "  Migrating from registry.emrbear.com"
echo "============================================"

# bear5
for TAG in master testing-c642eb testing-caba36 testing-fdd19f; do
  migrate "$DO_REGISTRY/bear5:$TAG" "$ECR_BASE/bear5:$TAG"
done

# bear6
for TAG in develop6-fbdd29 develop6-ffa01c develop6; do
  migrate "$DO_REGISTRY/bear6:$TAG" "$ECR_BASE/bear6:$TAG"
done

# bear-github
for TAG in main-954898 main-ad87de main-d7886f; do
  migrate "$DO_REGISTRY/bear-github:$TAG" "$ECR_BASE/bear-github:$TAG"
done

# bear-services (only 1 tag)
migrate "$DO_REGISTRY/bear-services:master-f39a206" "$ECR_BASE/bear-services:master-f39a206"

# bear-services-hds (only 1 tag)
migrate "$DO_REGISTRY/bear-services-hds:latest" "$ECR_BASE/bear-services-hds:latest"

# bear-stats
for TAG in master-f15e2c master-f57e4e v1.3.4; do
  migrate "$DO_REGISTRY/bear-stats:$TAG" "$ECR_BASE/bear-stats:$TAG"
done

# bear-xero
for TAG in master-f5972c master-fa0ccc master; do
  migrate "$DO_REGISTRY/bear-xero:$TAG" "$ECR_BASE/bear-xero:$TAG"
done

# bear_x12 (only 1 tag)
migrate "$DO_REGISTRY/bear_x12:latest" "$ECR_BASE/bear_x12:latest"

# =============================================
#  FROM ghcr.io/emrbear → ECR
# =============================================
echo ""
echo "============================================"
echo "  Migrating from ghcr.io/emrbear"
echo "============================================"

# prex-cerner (nested path → flat ECR name)
for TAG in 270f6297 8f5f9d44 testing-8f5f9d44; do
  migrate "$GHCR_REGISTRY/prex-cerner/prex-cerner:$TAG" "$ECR_BASE/prex-cerner:$TAG"
done

# prex-surescripts
for TAG in 97c1d743 cec4bcc8 testing-cec4bcc8; do
  migrate "$GHCR_REGISTRY/prex-surescripts/prex-surescripts:$TAG" "$ECR_BASE/prex-surescripts:$TAG"
done

# prex-idology
for TAG in c135cf59 1b59195e debuggin-request; do
  migrate "$GHCR_REGISTRY/prex-idology/prex-idology:$TAG" "$ECR_BASE/prex-idology:$TAG"
done

# prex-saaspass
for TAG in df08cf5a testing-df08cf5a; do
  migrate "$GHCR_REGISTRY/prex-saaspass/prex-saaspass:$TAG" "$ECR_BASE/prex-saaspass:$TAG"
done

# trip-reporter
for TAG in 6cb0ad2 19eacb7 1.1.0; do
  migrate "$GHCR_REGISTRY/trip-reporter/trip-reporter:$TAG" "$ECR_BASE/trip-reporter:$TAG"
done

# bear-gemini (flat path on ghcr)
for TAG in main-493aff main pr-42; do
  migrate "$GHCR_REGISTRY/bear-gemini:$TAG" "$ECR_BASE/bear-gemini:$TAG"
done

# =============================================
#  Summary
# =============================================
echo ""
echo "============================================"
echo "  Migration complete!"
echo "============================================"
echo ""
echo "Verify with:"
echo "  aws ecr describe-images --repository-name <repo> --region $AWS_REGION --query 'imageDetails[*].imageTags' --output table"
echo ""
echo "Remember to clean up local images if disk space is a concern:"
echo "  docker image prune -a"
