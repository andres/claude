#!/bin/bash
# Step 1: List the last 3 tags for each image on registry.emrbear.com and ghcr.io
# Uses Docker Registry HTTP API v2

REGISTRY="https://registry.emrbear.com"
AUTH="emrbear:assyrian-bliss-trauma-collard-pluto-initiate-back"

# Images hosted on registry.emrbear.com
REGISTRY_IMAGES=(
  bear5
  bear6
  bear-gemini
  bear-github
  bear-services
  bear-services-hds
  bear-stats
  bear-xero
  bear_x12
  bear_referrals
)

# Images hosted on ghcr.io/emrbear
GHCR_IMAGES=(
  prex-cerner
  prex-idology
  prex-saaspass
  prex-surescripts
  trip-reporter
)

echo "============================================"
echo "  registry.emrbear.com — Tag Listing"
echo "============================================"

for IMAGE in "${REGISTRY_IMAGES[@]}"; do
  echo ""
  echo "--- $IMAGE ---"
  TAGS=$(curl -s -u "$AUTH" "$REGISTRY/v2/$IMAGE/tags/list" 2>/dev/null)

  if echo "$TAGS" | jq -e '.tags' > /dev/null 2>&1; then
    echo "$TAGS" | jq -r '.tags | if length > 3 then .[-3:] else . end | .[]'
    COUNT=$(echo "$TAGS" | jq '.tags | length')
    echo "  (total tags: $COUNT)"
  else
    echo "  ERROR: Could not fetch tags. Response: $TAGS"
  fi
done

echo ""
echo "============================================"
echo "  ghcr.io/emrbear — Tag Listing"
echo "============================================"
echo ""
echo "NOTE: ghcr.io images require a GitHub PAT for private repos."
echo "Listing via API (if public):"

for IMAGE in "${GHCR_IMAGES[@]}"; do
  echo ""
  echo "--- $IMAGE ---"
  TAGS=$(curl -s "https://ghcr.io/v2/emrbear/$IMAGE/tags/list" 2>/dev/null)
  if echo "$TAGS" | jq -e '.tags' > /dev/null 2>&1; then
    echo "$TAGS" | jq -r '.tags | if length > 3 then .[-3:] else . end | .[]'
    COUNT=$(echo "$TAGS" | jq '.tags | length')
    echo "  (total tags: $COUNT)"
  else
    echo "  Requires authentication or not found. Response: $TAGS"
  fi
done
