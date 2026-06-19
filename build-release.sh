#!/usr/bin/env bash
#
# Build an installable LimeSurvey plugin package.
#
# LimeSurvey requires the plugin folder, the main PHP file, the class name and
# the <name> in config.xml to all be identical ("LTIPlugin"), and config.xml to
# sit directly inside that folder. It also needs the Composer dependencies in
# vendor/, which is gitignored and therefore NOT present in a plain "git clone"
# or a GitHub "Download ZIP".
#
# This script produces LTIPlugin-<version>.zip whose single top-level folder is
# "LTIPlugin/", containing the tracked files plus a freshly installed vendor/.
#
# Usage:  ./build-release.sh
#
set -euo pipefail

cd "$(dirname "$0")"

VERSION="$(grep -oE '<version>[^<]+' config.xml | head -1 | sed 's/<version>//')"
STAGE="$(mktemp -d)"
OUT="$(pwd)/LTIPlugin-${VERSION}.zip"

echo "Building LTIPlugin ${VERSION} ..."

# Install production dependencies into a clean vendor/
composer install --no-dev --optimize-autoloader --quiet

# Stage the tracked files under the required folder name
mkdir -p "${STAGE}/LTIPlugin"
git archive HEAD | tar -x -C "${STAGE}/LTIPlugin"

# Bundle the dependencies and drop dev-only files
cp -R vendor "${STAGE}/LTIPlugin/vendor"
rm -f "${STAGE}/LTIPlugin/.gitignore" "${STAGE}/LTIPlugin/build-release.sh"

# Package
rm -f "${OUT}"
( cd "${STAGE}" && zip -rq "${OUT}" LTIPlugin -x "*.DS_Store" )
rm -rf "${STAGE}"

echo "Created ${OUT}"
echo "Top-level folder inside the archive:"
unzip -Z1 "${OUT}" | awk -F/ 'NR<=12{print "  "$0}'
