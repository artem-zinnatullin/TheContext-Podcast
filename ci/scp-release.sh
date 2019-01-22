#!/bin/bash
set -eu

# Expected environment variables:
# TRAVIS_REPO_SLUG, TRAVIS_TAG
# STORAGE_USER, STORAGE_HOST, STORAGE_PATH

RELEASE_FILE_CONTENT_TYPE="audio/mpeg"

# Use GitHub API to get the release file URL associated with a Git tag.

RELEASES="$(curl \
  --silent \
  --show-error \
  --request GET \
  --header "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GITHUB_SLUG}/releases"
)"

RELEASE_FILE="$(
  echo "${RELEASES}" | jq --raw-output "
    .[] |
    select(.tag_name == \"${GITHUB_TAG}\") |
    .assets |
    .[] |
    select(.content_type = \"${RELEASE_FILE_CONTENT_TYPE}\")
  "
)"

RELEASE_FILE_URL="$(echo "${RELEASE_FILE}" | jq --raw-output ".browser_download_url")"
RELEASE_FILE_NAME="$(echo "${RELEASE_FILE}" | jq --raw-output ".name")"

# Download the release file.

curl \
  --silent \
  --show-error \
  --location "${RELEASE_FILE_URL}" \
  --output "${RELEASE_FILE_NAME}"

# Upload the release file to the remote location.

scp "${RELEASE_FILE_NAME}" ${STORAGE_USER}@${STORAGE_HOST}:${STORAGE_PATH}