#!/usr/bin/env bash

set -euo pipefail

check_fixture_paths() {
  local relative_directory="$1"
  local fingerprints_filename="$2"
  shift 2

  local fixture_keys=("$@")

  local filename
  local filenames
  local fixture_path
  local all_files_exist=true

  filenames=("${fingerprints_filename}")

  for fixture_data in "${fixture_keys[@]}"; do
    IFS="|" read -r slug name email <<< "${fixture_data}"

    filenames+=("${slug}.gpg")
    filenames+=("${slug}.asc")
  done

  for filename in "${filenames[@]}"; do
    fixture_path="${relative_directory%/}/${filename}"

    if [[ ! -f "${fixture_path}" ]]; then
      printf 'Fixture file does not exist: %s\n' "${fixture_path}" >&2
      all_files_exist=false
    fi
  done

  if [[ "${all_files_exist}" == true ]]; then
    echo "All fixture files exist. Exiting helper..."
    return 0
  fi

  return 1
}

fixture_directory="${1:-molecule/debian/fixtures/gpg}"
fixture_keys=(
  "vendor-alpha|Vendor Alpha Fixture|alpha@example.invalid"
  "vendor-beta|Vendor Beta Fixture|beta@example.invalid"
  "vendor-charlie|Vendor Charlie Fixture|charlie@example.invalid"
  "vendor-delta|Vendor Delta Fixture|delta@example.invalid"
)
fingerprint_filename="fingerprints.txt"

if check_fixture_paths "${fixture_directory}" "${fingerprint_filename}" "${fixture_keys[@]}"; then
  exit 0
fi

mkdir -p "${fixture_directory}"

export GNUPGHOME
GNUPGHOME="$(mktemp -d)"
chmod 0700 "${GNUPGHOME}"

cleanup() {
  rm -rf "${GNUPGHOME}"
}
trap cleanup EXIT

fingerprint_file="${fixture_directory}/${fingerprint_filename}"
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
find "${fixture_directory}" -maxdepth 1 -type f ! -name .keep -print | sort
