#!/usr/bin/env bash
set -euo pipefail
flutter create --platforms=android,ios,web --org com.veeadventures .
python tool/configure_platforms.py
flutter pub get
