#!/bin/bash
# Generates a kubeconfig for the readonly-user ServiceAccount
# Usage: ./gen-kubeconfig.sh [output-file]
# Requires: kubectl configured with admin access to the cluster

set -e

OUTPUT="${1:-readonly-user-kubeconfig.yaml}"
SA_NAME="readonly-user"
NAMESPACE="default"
SECRET_NAME="readonly-user-token"

echo "Fetching cluster info..."
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}')
TOKEN=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 --decode)

cat > "$OUTPUT" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: ${CLUSTER_NAME}
    cluster:
      server: ${SERVER}
      certificate-authority-data: ${CA_DATA}
contexts:
  - name: readonly@${CLUSTER_NAME}
    context:
      cluster: ${CLUSTER_NAME}
      user: ${SA_NAME}
      namespace: ${NAMESPACE}
current-context: readonly@${CLUSTER_NAME}
users:
  - name: ${SA_NAME}
    user:
      token: ${TOKEN}
EOF

echo "Kubeconfig written to: $OUTPUT"
echo "Share this file with the user. They can use it with: KUBECONFIG=$OUTPUT kubectl get pods"
