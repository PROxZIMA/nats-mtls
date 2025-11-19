#!/bin/bash
set -euo pipefail

CERT_DIR="./certs"
NATS_CERT_DIR="$CERT_DIR/nats"
VALIDITY_DAYS=365

echo "=========================================="
echo "Generating NATS mTLS Certificates"
echo "=========================================="

# Create certificates directories
mkdir -p "$NATS_CERT_DIR"/{ca,broker,leaf,clients}

# ============================================================================
# 1. Generate Common Root CA for NATS
# ============================================================================
echo ""
echo "1. Generating NATS Root CA..."
step certificate create "NATS Root CA" \
  "$NATS_CERT_DIR/ca/ca.crt" "$NATS_CERT_DIR/ca/ca.key" \
  --profile root-ca \
  --no-password \
  --insecure \
  --not-after="$((VALIDITY_DAYS * 24))h"

echo "   ✓ NATS Root CA generated"

# ============================================================================
# 2. Generate NATS Broker Server Certificate
# ============================================================================
echo ""
echo "2. Generating NATS Broker Server Certificate..."
step certificate create nats-broker.nats-system.svc.cluster.local \
  "$NATS_CERT_DIR/broker/server.crt" "$NATS_CERT_DIR/broker/server.key" \
  --profile leaf \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$NATS_CERT_DIR/ca/ca.crt" \
  --ca-key "$NATS_CERT_DIR/ca/ca.key" \
  --san nats-broker.nats-system.svc.cluster.local \
  --san nats-broker.nats-system.svc \
  --san nats-broker \
  --san localhost \
  --san 127.0.0.1 \
  --san 129.154.247.85 \
  --no-password \
  --insecure

echo "   ✓ NATS Broker server certificate generated"

# ============================================================================
# 3. Generate NATS Leaf Server Certificate
# ============================================================================
echo ""
echo "3. Generating NATS Leaf Server Certificate..."
step certificate create nats-leaf.nats-system.svc.cluster.local \
  "$NATS_CERT_DIR/leaf/server.crt" "$NATS_CERT_DIR/leaf/server.key" \
  --profile leaf \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$NATS_CERT_DIR/ca/ca.crt" \
  --ca-key "$NATS_CERT_DIR/ca/ca.key" \
  --san nats-leaf.nats-system.svc.cluster.local \
  --san nats-leaf.nats-system.svc \
  --san nats-leaf \
  --san localhost \
  --san 127.0.0.1 \
  --no-password \
  --insecure

echo "   ✓ NATS Leaf server certificate generated"

# ============================================================================
# 4. Generate Publisher Client Certificates (for publisher -> broker)
# ============================================================================
echo ""
echo "4. Generating Publisher Client Certificates..."
step certificate create nats-publisher \
  "$NATS_CERT_DIR/clients/publisher-client.crt" "$NATS_CERT_DIR/clients/publisher-client.key" \
  --profile leaf \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$NATS_CERT_DIR/ca/ca.crt" \
  --ca-key "$NATS_CERT_DIR/ca/ca.key" \
  --no-password \
  --insecure

echo "   ✓ Publisher client certificate generated"

# ============================================================================
# 5. Generate Leaf Node Client Certificates (for leaf -> broker)
# ============================================================================
echo ""
echo "5. Generating Leaf Node Client Certificates (for leaf -> broker)..."
step certificate create nats-leaf-client \
  "$NATS_CERT_DIR/clients/leaf-client.crt" "$NATS_CERT_DIR/clients/leaf-client.key" \
  --profile leaf \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$NATS_CERT_DIR/ca/ca.crt" \
  --ca-key "$NATS_CERT_DIR/ca/ca.key" \
  --no-password \
  --insecure

echo "   ✓ Leaf client certificate generated"

# ============================================================================
# 6. Generate Subscriber Client Certificates (for subscriber -> leaf)
# ============================================================================
echo ""
echo "6. Generating Subscriber Client Certificates..."
step certificate create nats-subscriber \
  "$NATS_CERT_DIR/clients/subscriber-client.crt" "$NATS_CERT_DIR/clients/subscriber-client.key" \
  --profile leaf \
  --not-after="$((VALIDITY_DAYS * 24))h" \
  --ca "$NATS_CERT_DIR/ca/ca.crt" \
  --ca-key "$NATS_CERT_DIR/ca/ca.key" \
  --no-password \
  --insecure

echo "   ✓ Subscriber client certificate generated"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
echo "NATS Certificate Generation Complete!"
echo "=========================================="
echo ""
echo "Certificate Structure:"
echo "  Root CA: $NATS_CERT_DIR/ca/"
echo "    └── ca.crt, ca.key"
echo ""
echo "  Broker Server: $NATS_CERT_DIR/broker/"
echo "    └── server.crt, server.key"
echo ""
echo "  Leaf Server: $NATS_CERT_DIR/leaf/"
echo "    └── server.crt, server.key"
echo ""
echo "  Client Certificates: $NATS_CERT_DIR/clients/"
echo "    ├── publisher-client.crt, publisher-client.key  (publisher -> broker)"
echo "    ├── leaf-client.crt, leaf-client.key            (leaf -> broker)"
echo "    └── subscriber-client.crt, subscriber-client.key (subscriber -> leaf)"
echo ""
echo "Certificate Usage:"
echo "  Publisher -> Broker mTLS:"
echo "    - Publisher uses: ca.crt, publisher-client.{crt,key}"
echo "    - Broker uses: ca.crt, broker/server.{crt,key}"
echo ""
echo "  Leaf -> Broker mTLS:"
echo "    - Leaf uses: ca.crt, leaf-client.{crt,key}"
echo "    - Broker uses: ca.crt, broker/server.{crt,key}"
echo ""
echo "  Subscriber -> Leaf mTLS:"
echo "    - Subscriber uses: ca.crt, subscriber-client.{crt,key}"
echo "    - Leaf uses: ca.crt, leaf/server.{crt,key}"
echo ""
echo "IMPORTANT: Deploy certificates to appropriate clusters:"
echo "  VM A (Broker) needs:"
echo "    - ca.crt"
echo "    - broker/server.{crt,key}"
echo "    - clients/publisher-client.{crt,key}"
echo "    - clients/leaf-client.{crt,key} (for leaf node verification)"
echo ""
echo "  VM B (Leaf) needs:"
echo "    - ca.crt"
echo "    - leaf/server.{crt,key}"
echo "    - clients/leaf-client.{crt,key} (for connecting to broker)"
echo "    - clients/subscriber-client.{crt,key}"
echo ""
