#!/usr/bin/env bash
set -euo pipefail

VERSION="openssl-3.5.4"
BASE_URL="https://github.com/openssl/openssl/releases/download/${VERSION}"
EXPECTED_FPR="BA5473A2B0587B07FB27CF2D216094DFD0CB81EF"

log() {
  echo "==> $*" >&2
}

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

log "Lade OpenSSL ${VERSION}"
curl -sSLO "${BASE_URL}/${VERSION}.tar.gz"
curl -sSLO "${BASE_URL}/${VERSION}.tar.gz.asc"
curl -sSLO "${BASE_URL}/${VERSION}.tar.gz.sha256"

log "Prüfe SHA256"
sha256sum -c "${VERSION}.tar.gz.sha256" >&2

log "Initialisiere temporären GPG Keyring"
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
trap 'rm -rf "$GNUPGHOME"' EXIT

gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$EXPECTED_FPR" >&2

log "Prüfe GPG Signatur"
gpg --batch --verify "${VERSION}.tar.gz.asc" "${VERSION}.tar.gz" >&2


log "Verifizierte Werte for Dockerfile"
SHA256=$(cut -d' ' -f1 "${VERSION}.tar.gz.sha256")

cat <<EOF
VERSION_OPENSSL=${VERSION}
SHA256_OPENSSL=${SHA256}
OPGP_OPENSSL=${EXPECTED_FPR}
EOF

