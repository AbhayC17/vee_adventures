#!/usr/bin/env bash
set -euo pipefail

flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn

echo "Web build ready in build/web"
