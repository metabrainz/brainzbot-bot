#!/bin/bash
#
# Build image from the currently checked out version of the brainzbot-bot
# and push it to the Docker Hub, with an optional tag (by default "latest").
#
# Usage:
#   $ ./push.sh [tag]

cd "$(dirname "${BASH_SOURCE[0]}")/../"

# Save the current git status
git describe --tags --dirty --always > .git-version

TAG_PART=${1:-latest}
docker build --target prod -t metabrainz/brainzbot-bot:$TAG_PART \
        --build-arg GIT_COMMIT_SHA=$(git describe --tags --dirty --always) .
docker push metabrainz/brainzbot-bot:$TAG_PART
