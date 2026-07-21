#!/usr/bin/env bash

set -euo pipefail

fixture_directory="${1:-molecule/debian/fixtures/gpg}"

mkdir -p "${fixture_directory}"

export GNUPGHOME
GNUPGHOME="$(mktemp -d)"
chmod 0700 "${GNUPGHOME}"

cleanup() {
  rm -rf "${GNUPGHOME}"
}
trap cleanup EXIT

fixture_keys=(
  "vendor-alpha|Vendor Alpha Fixture|alpha@example.invalid"
  "vendor-beta|Vendor Beta Fixture|beta@example.invalid"
  "vendor-charlie|Vendor Charlie Fixture|charlie@example.invalid"
  "vendor-delta|Vendor Delta Fixture|delta@example.invalid"
)

fingerprint_file="${fixture_directory}/fingerprints.txt"
: > "${fingerprint_file}"

for fixture_key in "${fixture_keys[@]}"; do
  IFS="|" read -r slug name email <<< "${fixture_key}"

  user_id="${name} <${email}>"

  echo "Generating ${user_id}"

  gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "" \
    --quick-generate-key \
    "${user_id}" \
    rsa2048 \
    sign \
    never

  fingerprint="$(
    gpg \
      --batch \
      --with-colons \
      --list-keys "${email}" |
      awk -F: '$1 == "fpr" { print $10; exit }'
  )"

  if [[ -z "${fingerprint}" ]]; then
    echo "Unable to determine fingerprint for ${email}" >&2
    exit 1
  fi

  # ASCII-armored public key.
  gpg \
    --batch \
    --yes \
    --armor \
    --export-options export-minimal \
    --output "${fixture_directory}/${slug}.asc" \
    --export "${fingerprint}"

  # Binary public keyring, suitable for a .gpg APT keyring fixture.
  gpg \
    --batch \
    --yes \
    --export-options export-minimal \
    --output "${fixture_directory}/${slug}.gpg" \
    --export "${fingerprint}"

  printf '%s %s\n' "${slug}" "${fingerprint}" >> "${fingerprint_file}"
done

echo
echo "Generated fixtures:"
find "${fixture_directory}" -maxdepth 1 -type f -print | sort
