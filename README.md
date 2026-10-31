# Movement Missions

**Movement Missions** (starring Vee the tiger) is a preschool adventure game built with Flutter and Flame. Children explore familiar environments, solve discovery missions, follow short stories, and complete simple movement challenges with Vee, a friendly tiger companion.

This README is the consolidated project handover document. Earlier standalone Markdown notes have been removed so the repository has one main source of project documentation.

## 1. Project at a glance

### Main experiences

- **SPOT** — a real-world discovery activity. Children can choose or capture a picture, identify an item from the curated content catalogue, and unlock a child-friendly discovery.
- **EXPLORE** — interactive indoor and outdoor worlds with discoverable objects, small challenges, surprise events, and hidden areas.
- **PLAY** — short adventure episodes combining a story, choices, movement challenges, puzzles, discoveries, and a finale.
- **Storybook look** — one visual language everywhere: cream pages, illustrated scenes (indoor and outdoor), deep-teal pill buttons, a top bar with step dots, and big friendly headlines. Backgrounds are drawn in code until generated artwork is added (see `docs/ASSET_PROMPTS.md`).
- **EXPLORE is a hide-and-seek game** — peek behind animated hiding spots for items (with a fun fact and a sticker), friendly critters and rare golden finds. A sparkle meter brings surprises, rounds keep finding new things, worlds can be mastered, and every round favours stickers the child does not have yet.
- **Discover anything (optional, off by default)** — a grown-up can let SPOT name and talk about almost any object in a photo. Pictures of people are refused, text is filtered on the device and checked again on the server, and the photo is never stored. See `api/moderate.ts` and `lib/services/spot/`.
- **Vee's Meadow** — a free-play Flame world where every tap answers back: fireflies pop into collectable stars, butterflies swirl, the tree rustles and flowers bloom. It grows as the child plays (a treasure chest, then a magic portal appear).
- **Sticker book** — every discovery in the game as a sticker to collect, with mystery stickers for the ones not yet found.
- **Companion and family views** — Vee's adventure world, the discovery journal, saved progress, and a parent-gated activity report.
- **Progression** — stars, discoveries, activity history, environment preference, and child profile information are saved locally on the device/browser.

The app also includes onboarding, adaptive layouts, readable text/color treatments, rewards, movement instructions, and a shared design system.

## 2. Technology stack

| Area | Technology | Purpose |
|---|---|---|
| App UI | Flutter / Dart | Screens, navigation, responsive layouts, and state-driven UI |
| Interactive game elements | Flame | Vee's Meadow and the reward celebration (canvas-drawn, tap-reactive) in `lib/game/` |
| AI requests | Vercel serverless functions + Groq API | Server-side text and image requests for supported AI features |
| Local persistence | `shared_preferences` | Saves the profile, stars, discoveries, and activity progress locally |
| Media and networking | `image_picker`, `http`, `flutter_svg` | Picture selection, HTTP requests, and SVG support |
| Content | Dart catalogues and JSON assets | Curated facts, movement definitions, episode data, and asset references |
| Automated checks | Flutter test/analyzer + GitHub Actions | Static analysis, regression tests, contrast checks, and web builds |

The app's AI endpoint is OpenAI-compatible and configured in `api/groq.ts`. The server currently selects the model `qwen/qwen3.8-27b`. The API key belongs in Vercel's environment settings; it must not be embedded in the Flutter application.

## 3. How the application is organised

```text
.
├── api/                         # Vercel API functions: AI proxy and health check
├── assets/
│   ├── data/                     # JSON catalogues and episode data
│   ├── fonts/                    # Fredoka font family
│   ├── items/                    # 20 item icons (apple, banana, ... toy)
│   ├── scenes/                   # Backgrounds (meadow, indoor, close-up) and the two doors
│   └── vee/                      # Vee's eight poses and the movement-frame slot
├── lib/
│   ├── app/                      # App setup, controller, routing, theme, design tokens
│   ├── features/                 # Onboarding, hub, SPOT, EXPLORE, PLAY, rewards, companion
│   ├── game/                     # Flame game rendering and interaction
│   ├── models/                   # Typed models and curated content catalogues
│   ├── services/                 # AI, discovery, activity selection, storage, movement, safety
│   ├── widgets/                  # Reusable UI components
│   └── main.dart                 # Application entry point
├── test/                         # Unit, flow, catalogue, theme, and accessibility tests
├── tool/                         # Platform/bootstrap and web-build helper scripts
├── web/                          # Flutter web entry page and manifest
├── android/                      # Native scaffold generated by the bootstrap script
├── ios/                          # Native scaffold generated by the bootstrap script
├── pubspec.yaml                  # Flutter dependencies and bundled assets
├── pubspec.lock                  # Locked Flutter/Dart dependencies
├── package.json                  # Node/Vercel function dependency manifest
├── package-lock.json             # Locked Node dependencies
├── vercel.json                   # Vercel build output, routing, cache headers, function limits
└── README.md                     # Project setup and handover guide
```

### Important modules

- `lib/app/app_controller.dart` — shared application state, profile/progression management, and completion persistence.
- `lib/app/game_app_scope.dart` — exposes controller state to widgets that depend on it.
- `lib/app/root_router.dart` and `lib/app/routes.dart` — top-level navigation.
- `lib/models/content_catalog.dart` — curated items, properties, approved facts, and indoor/outdoor world definitions.
- `lib/services/discovery_engine.dart` — discovery packs and surprise events used by the activities.
- `lib/services/movement/movement_catalog.dart` — movement definitions, age-appropriate instructions, and movement selection pools. Keep existing movement IDs stable because other content can refer to them.
- `lib/services/play/play_episode_catalog.dart` and `assets/data/play_episodes.json` — PLAY episode data and catalogue validation.
- `lib/services/storage/game_storage.dart` — persistence and saved-state handling. `AppController.scheduleSave()` merges rapid saves into one quiet write; `save()` and `finishActivity()` still write immediately.
- `lib/services/play/play_puzzles.dart` — builds the puzzles (drag-match, odd-one-out, pattern, clue guess). The correct answer is always among the options; unit tests enforce it for every episode.
- `lib/widgets/puzzle_card.dart` — shows any puzzle, with a gentle shake on a wrong answer and a pop on a right one. Drag puzzles also accept a tap.
- `lib/widgets/scene_scaffold.dart`, `scene_background.dart`, `scene_ui.dart`, `world_shell.dart` — the shared screen frame (scene, top bar, step pill, tags, round buttons). `lib/app/brand.dart` holds the game's name.
- `lib/widgets/juicy_tap.dart`, `lib/widgets/vee_avatar.dart` — tap feedback (squish on touch-down) and Vee's reactive poses.
- `lib/widgets/sticker_book.dart` — the collection screen.
- `lib/game/world_adventure_game.dart`, `lib/game/living_world.dart` — the Flame meadow and the widget that hosts it. This is the only place Flame is used.
- `lib/features/meadow/meadow_screen.dart` — Vee's Meadow.
- `lib/services/ai/ai_provider.dart` — client-side request and response handling for the `/api/groq` endpoint.
- `api/groq.ts` — validates requests/images, reads `GROQ_API_KEY`, forwards requests to the AI provider, and returns structured errors.
- `api/health.ts` — simple endpoint for checking whether the proxy is running and whether its environment key is configured.

## 4. Main application flow

1. `lib/main.dart` initialises Flutter and starts `VeesAdventuresApp`.
2. App setup creates and initialises the application controller and loads locally saved state.
3. Onboarding collects the child's profile and preferences, including movement intensity and indoor/outdoor mode.
4. The Adventure Hub offers SPOT, EXPLORE, and PLAY.
5. The activities use the curated catalogue/discovery engine and the shared controller to record completions, stars, discoveries, and history.
6. State is persisted locally so it can be restored on the same browser/device. The current implementation does **not** synchronise progress between devices.

The catalogues are the source of approved educational facts and discovery content. AI is used only for SPOT photo identification and the optional parent-area story; it should not replace the content catalogue or produce unsafe instructions for children. Surprises, puzzles and PLAY stories are chosen locally and instantly, with no network request (an earlier version asked the AI to pick a surprise, which froze the screen for several seconds).

## 5. Requirements

- Flutter stable **3.47.x** (the Flutter workflow currently pins 3.47.4).
- Dart **3.13 or newer**, within the SDK range in `pubspec.yaml`.
- Node.js **20 or newer** and npm, for the Vercel functions.
- A Vercel account/project for hosted AI requests.
- A Groq API key for AI features. Create/manage it through the Groq console, then store it in Vercel environment settings. `.env.example` lists the variable names. The proxy only accepts requests from your own site (add others with `ALLOWED_ORIGINS`) and rate-limits each visitor.
- Chrome or another supported browser for web testing.

## 6. Get started locally

Run commands from the project root—the directory containing `pubspec.yaml`, `package.json`, and `vercel.json`.

### Install Flutter dependencies

```bash
flutter pub get
```

### Run the app without the local Vercel API

```bash
flutter run -d chrome
```

This is useful for UI work. The `/api/groq` serverless function is not started by `flutter run -d chrome`, so AI features that depend on that route need the Vercel development server.

### Install Node dependencies

```bash
npm ci
```

Use `npm ci` to recreate the dependencies pinned in `package-lock.json`. `node_modules/` is intentionally not included in the project ZIP.

## 7. Configure the AI proxy for local web testing

The Flutter web app sends AI requests to `/api/groq`. Vercel runs `api/groq.ts` and supplies the secret key from the environment. Do not place the real key in Dart code, `--dart-define`, GitHub, or a committed `.env` file.

1. Install the Vercel CLI if it is not already installed:

   ```bash
   npm install --global vercel
   ```

2. Log in and connect this project to the correct Vercel project:

   ```bash
   vercel login
   vercel link
   ```

3. Add the secret when prompted. Repeat for every environment in which AI requests should work:

   ```bash
   vercel env add GROQ_API_KEY development
   vercel env add GROQ_API_KEY production
   ```

   The `.env.example` file documents the required variable name; its sample value is only a placeholder.

4. Pull the development environment and start Vercel locally:

   ```bash
   vercel pull --environment=development
   vercel dev
   ```

5. Open the local URL printed by Vercel. Keep that terminal running during AI testing. After Flutter source changes, rebuild the web output before deployment.

### Native Android/iOS builds

For native builds, point the app at the deployed proxy endpoint so the API key remains on the server:

```bash
flutter run --dart-define=AI_BASE_URL=https://YOUR-VERCEL-DOMAIN.vercel.app/api/groq
```

Replace the example domain with the deployed project domain. Do **not** ship `GROQ_API_KEY` inside a mobile app.

If native platform scaffolding is missing from the checkout, recreate it from the project root. On macOS/Linux, run:

```bash
bash tool/bootstrap_platforms.sh
```

On Windows PowerShell, run:

```powershell
.\tool\bootstrap_platforms.ps1
```

These scripts recreate Android/iOS/web platform scaffolding, apply platform configuration where supported, and run `flutter pub get`. Review any generated platform changes before committing or releasing.

## 8. Build and deploy to Vercel

Build the Flutter web application:

```bash
flutter build web --release --no-web-resources-cdn
```

`--no-web-resources-cdn` bundles CanvasKit with the app instead of downloading it from a Google server, which keeps the game free of third-party requests. After building, open the game with the browser's Network tab visible and confirm every request goes to your own domain.

Then deploy from the linked project root:

```bash
vercel --prod
```

`vercel.json` points Vercel to `build/web`, rewrites the Flutter web routes to `index.html`, applies cache headers, and assigns a 60-second maximum duration to the Groq proxy function. If the production API key is added or changed after a deployment, redeploy so the function receives the updated environment.

## 9. Tests and quality checks

Run these commands before handing off changes:

```bash
flutter analyze
flutter test
flutter build web --release
```

The current test suite covers areas including:

- Adventure session stage transitions and completion rules.
- Completion/reward idempotency and restoration of saved snapshots.
- Movement catalogue uniqueness and profile-specific selection.
- PLAY episode data, IDs, environment filtering, and seeded selection.
- Content/discovery catalogue expectations.
- Theme contrast and accessibility checks.

GitHub Actions also runs Flutter analysis/tests/web builds and a dedicated contrast-accessibility test.

## 10. Useful endpoints and troubleshooting

### Health check

After starting `vercel dev`, open `/api/health`. The response reports the service, configured model, and whether `GROQ_API_KEY` is present. It does not make a full AI completion request.

### Check that the proxy route exists

This intentionally invalid request should return HTTP 400 because the `messages` array is missing:

```bash
curl -i -X POST "http://localhost:3000/api/groq" \
  -H "Content-Type: application/json" \
  -d "{}"
```

Common results:

- **`MISSING_GROQ_API_KEY` / HTTP 503** — the function is running but its Vercel environment does not have the key. Add the key to the correct environment and redeploy/pull it.
- **`INVALID_REQUEST` / HTTP 400** — the proxy route is responding; send a valid JSON body with a non-empty `messages` array for a real request.
- **HTTP 404** — check that `vercel dev` is running from this project root and that Vercel is linked to the intended project.
- **AI unavailable in `flutter run -d chrome`** — use `vercel dev` for web testing so the serverless route is available.
- **Assets or episodes fail to load** — run `flutter pub get`, confirm asset paths in `pubspec.yaml`, and ensure the corresponding assets/JSON files are present.

## 11. Before publishing (child-safety checklist)

Step-by-step release instructions are in `docs/PUBLISHING.md`; the artwork to create (with AI prompts) is in `docs/ASSET_PROMPTS.md`.


- **Photos in SPOT.** A child's photo is sent to the Groq AI through `/api/groq` to identify one object. If you publish in a kids' category (Apple Kids, Google Play Families) or to children under 13, check COPPA/GDPR-K rules with a lawyer and say so in your privacy policy, or switch SPOT to picture-pick only (the "Pick from pictures" button already works with no photo and no network).
- **No ads, external links or analytics** are included. Keep it that way: do not add packages that collect data.
- **Third-party requests.** Build with `--no-web-resources-cdn` and check the Network tab. Emoji and some text may still load a fallback font on web; if you see a request to another domain, bundle a font for it.
- **Parent gate.** The sum changes on every visit. For app-store review, test it with a real 5-year-old.
- **Rate limiting.** The proxy limit is per serverless instance. Add a shared store (for example Vercel KV) for a hard limit.
- **Accessibility.** Text stays large and high-contrast (see `test/theme/contrast_accessibility_test.dart`). The game respects the system "reduce motion" setting for tap squish and Vee's hop.
