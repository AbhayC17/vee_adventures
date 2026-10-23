$ErrorActionPreference='Stop'
flutter create --platforms=android,ios,web --org com.veeadventures .
python tool/configure_platforms.py
flutter pub get
