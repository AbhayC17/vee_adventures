# Publishing Movement Missions

Follow the steps in order. Steps marked **(you)** need your own accounts or
files; everything else is already done in this project.

## 0. One-time setup

```bash
flutter pub get          # Flutter 3.47.x, Dart 3.13+
npm ci                   # for the AI proxy in /api
```

## 1. Artwork

All artwork is already in the project as WebP: Vee's 8 poses, the 3 backgrounds,
the 2 doors, the 20 item icons and the app icon. Nothing to add.

To replace or add a picture later, see `docs/ASSET_PROMPTS.md` for prompts and
use the helper scripts (`pip install pillow numpy scipy`):

```bash
python tool/prepare_art.py scene  raw_meadow.png assets/scenes/bg_meadow.webp
python tool/prepare_art.py poses  raw_poses/ assets/vee/        # a folder of poses
python tool/prepare_art.py trim   raw_door.png assets/scenes/door_open.webp
python tool/slice_sticker_sheet.py sheet.png                    # 20 item icons
python tool/make_icons.py branding/app_icon_1024.png            # all app icons
```

## 2. Check it works on your computer

```bash
flutter analyze
flutter test
flutter run -d chrome --release      # always judge speed in --release
```

Never judge speed from `flutter run` in debug mode; it is many times slower.

## 3. (Recommended) Bundle an emoji font

Parts of the game still show emoji (for example the 🏠 and 🌳 on the
indoor/outdoor switch). On the web, Flutter otherwise downloads an emoji font
from Google the first time one appears, which can pause the game for a moment
and does not work offline. To avoid that:

1. Download **Noto Color Emoji** (free, SIL Open Font License) from
   <https://fonts.google.com/noto/specimen/Noto+Color+Emoji>.
2. Save the `.ttf` as `assets/fonts/NotoColorEmoji.ttf`.
3. In `pubspec.yaml`, under `fonts:` add (indent to match the Fredoka entry):

   ```yaml
       - family: NotoColorEmoji
         fonts:
           - asset: assets/fonts/NotoColorEmoji.ttf
   ```
4. Run `flutter pub get`. The theme already points at this font name, so no
   code change is needed. It adds a few MB to the download.

## 4. Deploy the web version (Vercel)

1. **(you)** Create a Vercel project and run `vercel link`.
2. **(you)** Add the secret: `vercel env add GROQ_API_KEY production`
   (and `development`). Optional: `ALLOWED_ORIGINS` for extra websites.
   Optional: `GROQ_GUARD_MODEL` (for example a Llama Guard model) to use a
   dedicated safety model for the "Discover anything" check; without it the
   main model checks the text. `/api/health` shows which model is used.
3. **(you)** In the Groq console set a **monthly spending limit** and enable
   alerts, so a leaked URL can never run up a bill.
4. Build and deploy:

   ```bash
   flutter build web --release --no-web-resources-cdn
   vercel --prod
   ```
5. Verify:
   * `https://YOUR-DOMAIN/api/health` says the key is configured.
   * `https://YOUR-DOMAIN/privacy.html` opens (after you fill in the
     `[PLACEHOLDERS]` in `web/privacy.html`).
   * Open the game with the browser's Network tab visible. Every request
     should go to your own domain.
   * SPOT works with a photo and with "Pick from pictures".

## 5. Android (Google Play)

```bash
bash tool/bootstrap_platforms.sh         # creates android/ and ios/, adds the
                                         # camera permission, locks landscape
python tool/make_icons.py branding/app_icon_1024.png   # Android and iOS icons
```

1. **(you)** Create a signing key once and keep it safe (losing it means you
   cannot update the app):
   `keytool -genkey -v -keystore ~/vee-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vee`
   then follow <https://docs.flutter.dev/deployment/android#signing-the-app>.
2. Build with your deployed proxy address (the AI key never goes in the app):

   ```bash
   flutter build appbundle --release \
     --dart-define=AI_BASE_URL=https://YOUR-DOMAIN/api/groq
   ```
3. **(you)** In Play Console: upload `build/app/outputs/bundle/release/app-release.aab`,
   choose **Target audience: ages 5 and under**, join the **Designed for
   Families** programme, fill in the **Data safety** form (photos are sent to
   a server only to identify an object and are not stored; no ads, no
   analytics), add the privacy policy URL, and complete the content rating.

## 6. iOS (App Store)

Needs a Mac with Xcode and an Apple developer account **(you)**.

1. Run the bootstrap and icon commands above, then `open ios/Runner.xcworkspace`.
2. Set your bundle identifier and team, then
   `flutter build ipa --release --dart-define=AI_BASE_URL=https://YOUR-DOMAIN/api/groq`.
3. In App Store Connect choose the **Kids** category (age band 5 and under),
   answer the privacy "nutrition label" (no tracking; photos processed to
   identify an object), and add the privacy policy URL.

## 7. Store listing pictures

* 4–8 landscape screenshots: hub, SPOT clue, EXPLORE world, PLAY puzzle,
  Meadow, reward screen, sticker book.
* Google Play feature graphic 1024 x 500 and a 512 x 512 icon.
* Never show real children's faces or personal data in screenshots.

## 8. Final checks before you press "Publish"

- [ ] Played every activity start to finish on a **real low-end Android device**.
- [ ] Watched 2–3 children aged 3–6 play without help; fixed what confused them.
- [ ] `flutter analyze` and `flutter test` are clean.
- [ ] Release build is fast (no 2–3 second pauses).
- [ ] Privacy policy is filled in, reviewed, and linked in each store.
- [ ] Groq spending limit set; Vercel logs checked for errors.
- [ ] Parent gate tested; settings and reports not reachable by a child.
- [ ] Version number raised in `pubspec.yaml` for every upload
      (`version: 1.0.1+2` means 1.0.1, build 2).

## Known limits

* The proxy's rate limit is per server instance (see README section 11).
* There is no sound yet. It needs an audio package, which is a separate decision.
* Child-facing text is English only.
