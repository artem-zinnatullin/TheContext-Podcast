#!/bin/bash
set -eu

# Expected environment variables:
# TRAVIS_REPO_SLUG, TRAVIS_TAG
# STORAGE_USER, STORAGE_PRIVATE_KEY, STORAGE_HOST, STORAGE_PATH

RELEASE_FILE_CONTENT_TYPE="audio/mpeg"
STORAGE_PRIVATE_KEY_FILE="storage.key"

# Use GitHub API to get the release file URL associated with a Git tag.

RELEASE_JSON="$(curl \
  --silent \
  --fail \
  --show-error \
  --request GET \
  --header "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/releases/tags/${TRAVIS_TAG}"
)"

RELEASE_FILE_JSON="$(
  echo "${RELEASE_JSON}" | jq --raw-output "
    .assets |
    .[] |
    select(.content_type = \"${RELEASE_FILE_CONTENT_TYPE}\")
  "
)"

RELEASE_FILE_URL="$(echo "${RELEASE_FILE_JSON}" | jq --raw-output ".browser_download_url")"
RELEASE_FILE_NAME="$(echo "${RELEASE_FILE_JSON}" | jq --raw-output ".name")"

# Download the release file.

curl \
  --silent \
  --fail \
  --show-error \
  --location "${RELEASE_FILE_URL}" \
  --output "${RELEASE_FILE_NAME}"

# Upload the release file to the remote location.

trap rm "${STORAGE_PRIVATE_KEY_FILE}" EXIT

echo "${STORAGE_PRIVATE_KEY}" > "${STORAGE_PRIVATE_KEY_FILE}"
scp -i "${STORAGE_PRIVATE_KEY_FILE}" "${RELEASE_FILE_NAME}" ${STORAGE_USER}@${STORAGE_HOST}:${STORAGE_PATH}
