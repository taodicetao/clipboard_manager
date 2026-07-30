#!/bin/bash
# One-time: create a self-signed code-signing certificate in login keychain.
# Re-running is idempotent: if the cert already exists, this script exits 0.
set -euo pipefail

CERT_NAME="ClipboardManager Self-Signed"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$CERT_NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "Cert '$CERT_NAME' already exists in login keychain. Skipping."
  exit 0
fi

TMPDIR=$(mktemp -d -t cm-cert)
trap 'rm -rf "$TMPDIR"' EXIT

KEY="$TMPDIR/key.pem"
CRT="$TMPDIR/cert.pem"
P12="$TMPDIR/bundle.p12"
CONF="$TMPDIR/req.cnf"

cat >"$CONF" <<EOF
[req]
distinguished_name = dn
prompt = no
x509_extensions = v3_req

[dn]
CN = $CERT_NAME
O  = Self-Signed
OU = Personal Use

[v3_req]
basicConstraints      = critical, CA:FALSE
keyUsage              = critical, digitalSignature
extendedKeyUsage      = critical, codeSigning
subjectKeyIdentifier  = hash
EOF

# 36500 days ~= 100 years.
openssl req -x509 \
  -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout "$KEY" \
  -out "$CRT" \
  -days 36500 \
  -nodes \
  -config "$CONF" \
  -extensions v3_req

# Bundle to PKCS#12 with a temp passphrase, then import.
TMP_PASS="cm-temp-$$"
openssl pkcs12 -export \
  -legacy \
  -inkey "$KEY" \
  -in "$CRT" \
  -out "$P12" \
  -name "$CERT_NAME" \
  -password "pass:$TMP_PASS"

security import "$P12" \
  -k "$KEYCHAIN" \
  -P "$TMP_PASS" \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  -A

# Allow codesign to use the private key without an interactive prompt every build.
SHA1=$(openssl x509 -in "$CRT" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')
security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "$(security default-keychain | tr -d ' "')" \
  "$KEYCHAIN" >/dev/null 2>&1 || true

echo "Created self-signed cert in login keychain:"
echo "  Name: $CERT_NAME"
echo "  SHA1: $SHA1"
echo "  Validity: 100 years"
echo
echo "Trusting cert for code signing in user trust settings..."
# Trust the cert specifically for code signing (user domain, no sudo needed).
security add-trusted-cert -p codeSign -k "$KEYCHAIN" "$CRT"

echo "Verifying codesign sees it..."
security find-identity -v -p codesigning "$KEYCHAIN" | grep "$CERT_NAME" || {
  echo "WARNING: cert imported but codesign cannot see it as a signing identity."
  echo "Open Keychain Access > login > Certificates > '$CERT_NAME' > Get Info > Trust"
  echo "and set 'Code Signing' to 'Always Trust'."
  exit 1
}
echo "Done."
