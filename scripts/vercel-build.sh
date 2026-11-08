#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${HOME}/.cache/parkgrid-flutter"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  mkdir -p "$(dirname "${FLUTTER_DIR}")"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --disable-analytics pub get --enforce-lockfile
flutter --disable-analytics build web --release

# Vercel's project is configured to publish the repository's web directory.
cp -a build/web/. web/

test -f web/index.html
test -f web/flutter_bootstrap.js
test -f web/main.dart.js
