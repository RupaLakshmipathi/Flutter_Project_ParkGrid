#!/usr/bin/env bash
set -Eeuo pipefail

trap 'status=$?; printf "Vercel Flutter build failed at line %s (exit %s): %s\\n" "${LINENO}" "${status}" "${BASH_COMMAND}" >&2; exit "${status}"' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"
echo "Project root: ${PROJECT_ROOT}"

FLUTTER_DIR="${HOME}/.cache/parkgrid-flutter"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "Downloading Flutter stable SDK into ${FLUTTER_DIR}..."
  mkdir -p "$(dirname "${FLUTTER_DIR}")"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

echo "Flutter SDK version:"
flutter --version

echo "Resolving Dart dependencies..."
flutter --disable-analytics pub get --enforce-lockfile

echo "Building Flutter web release..."
flutter --disable-analytics build web --release --verbose

# Vercel publishes Flutter's generated web build directly.
echo "Checking generated Vercel output..."
if [[ ! -f build/web/index.html ]]; then
  echo "Flutter build returned without build/web/index.html. Generated index.html files:" >&2
  find . -maxdepth 6 -type f -name index.html -not -path './.git/*' -print >&2 || true
  echo "Build directory contents:" >&2
  find build -maxdepth 5 -print >&2 || true
  exit 1
fi
test -f build/web/index.html
test -f build/web/flutter_bootstrap.js
test -f build/web/main.dart.js
