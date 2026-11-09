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

# Vercel publishes Flutter's generated web build directly.
test -f build/web/index.html
test -f build/web/flutter_bootstrap.js
test -f build/web/main.dart.js
