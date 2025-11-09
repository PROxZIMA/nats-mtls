#!/bin/bash
set -euo pipefail

CERT_DIR="./certs"
VALIDITY_DAYS=365

echo "=========================================="
echo "Generating Linkerd Certificates"
echo "=========================================="

# Create certificates directory
mkdir -p "$CERT_DIR"

# Generate root CA (shared between both clusters)
echo "Generating Root CA..."
step certificate create root.linkerd.cluster.local \
  "$CERT_DIR/ca.crt" "$CERT_DIR/ca.key" \
  --profile root-ca \
  --no-password \
  --insecure \
  --not-after="$((VALIDITY_DAYS * 24))h"

echo "Root CA generated: $CERT_DIR/ca.crt"

# Generate identity issuer certificate and key for Cluster A (VM A - Broker)
echo ""
echo "Generating identity certificate for Cluster A (Broker)..."
step certificate create identity.linkerd.cluster.local \
  "$CERT_DIR/cluster-a-issuer.crt" "$CERT_DIR/cluster-a-issuer.key" \
  --profile intermediate-ca \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$CERT_DIR/ca.crt" \
  --ca-key "$CERT_DIR/ca.key" \
  --no-password \
  --insecure

echo "Cluster A issuer certificate generated: $CERT_DIR/cluster-a-issuer.crt"

# Generate identity issuer certificate and key for Cluster B (VM B - Leaf)
echo ""
echo "Generating identity certificate for Cluster B (Leaf)..."
step certificate create identity.linkerd.cluster.local \
  "$CERT_DIR/cluster-b-issuer.crt" "$CERT_DIR/cluster-b-issuer.key" \
  --profile intermediate-ca \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$CERT_DIR/ca.crt" \
  --ca-key "$CERT_DIR/ca.key" \
  --no-password \
  --insecure

echo "Cluster B issuer certificate generated: $CERT_DIR/cluster-b-issuer.crt"

echo ""
echo "=========================================="
echo "Certificate Generation Complete!"
echo "=========================================="
echo ""
echo "Generated files:"
echo "  Root CA: $CERT_DIR/ca.crt"
echo "  Root CA Key: $CERT_DIR/ca.key"
echo "  Cluster A Issuer: $CERT_DIR/cluster-a-issuer.crt"
echo "  Cluster A Issuer Key: $CERT_DIR/cluster-a-issuer.key"
echo "  Cluster B Issuer: $CERT_DIR/cluster-b-issuer.crt"
echo "  Cluster B Issuer Key: $CERT_DIR/cluster-b-issuer.key"
echo ""
echo "IMPORTANT: Copy the appropriate certificate files to each VM:"
echo "  VM A needs: ca.crt, cluster-a-issuer.crt, cluster-a-issuer.key"
echo "  VM B needs: ca.crt, cluster-b-issuer.crt, cluster-b-issuer.key"
