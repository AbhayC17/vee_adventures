$ErrorActionPreference = 'Stop'

flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release

Write-Host "Web build ready in build/web"
