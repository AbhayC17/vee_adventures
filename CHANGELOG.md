# Changelog

## 2.1.0 – A new EXPLORE, "Discover anything", English only

- **EXPLORE redesigned as hide-and-seek.** Animated hiding spots (bush, rock, log indoors: basket, box, cushion) hide items, critters and a rare golden find. A sparkle meter earns surprises, "NEW!" tags and sticker counts show collecting progress, rounds favour stickers not yet found, and finding everything in a world masters it (a star badge on its card). Gentle nudge to rest after several rounds. A "Surprise me!" card picks a world at random.
- **SPOT "Discover anything"** (grown-up switch, off by default): one AI call names the object and may return up to two short facts. People and unsuitable pictures are refused; the game's catalogue always wins; every AI-written word passes rule-based filters, the game's safety validator and a server-side safety check (`api/moderate.ts`); facts are left out if a check cannot run. The child's own photo is shown on the reveal and a movement is chosen from the game's movement catalogue.
- When SPOT does not know an object (switch off), it now says so and offers the objects it does know instead of blaming the photo.
- Language switching removed from the whole game. English only.
- Fixed: the grown-up check still displayed "3 + 4" while asking for a random sum, which would have locked grown-ups out.
- New tests for the safety rules, the service, the EXPLORE board, the new setting and the EXPLORE screen.
- After the first real test run: world cards in EXPLORE now shrink their contents instead of overflowing by a pixel, and the analyzer's style notes were cleaned up.

## 2.0.0 – Storybook redesign ("Movement Missions"), final artwork

- All generated artwork is in the game: 8 Vee poses, 3 backgrounds, 2 doors, 20 item icons and the app icon, all as WebP (assets are now about 1.8 MB).
- Removed what the new design no longer uses: launch video and its player package, the old wooden panel, old doors, old background, raw PNGs, and dead code (`MagicalDoor`, `ParentPass`, `ProgressPips`, `AlignedPanel`, `routes.dart`).
- Fixed: the EXPLORE surprise picker was still calling the AI (a 2–3 second freeze). It now picks instantly on the device.
- Headings and the brand title sit on soft cream plaques so they stay readable over trees.
- Door and Vee scenes re-composed for the real picture proportions; the preloader loads only what the first screens need.
- Art tools improved: cleaner magenta removal, whole-folder Vee poses at one size, and a sticker splitter that copes with tightly packed sheets.

- Fixed after the first real `flutter analyze` / `flutter test` run: a compile error in the pattern-puzzle tile (`puzzle_card.dart`), two wrong tests (older pattern puzzle, bundled icon fallback), and every analyzer note. Added tests that check all item icons, poses and scenes are bundled.

(Details of the redesign itself:)

- New visual design matching the reference screens: cream pages, flat illustrated scenes, deep-teal pill buttons, round pale icon buttons, mint and coral tags, a top bar with the leaf logo, title, step pill with dots and a menu button.
- The game is now called **Movement Missions** (Vee is still the guide). The name lives in `lib/app/brand.dart`.
- New first-run flow: grown-up card, who is exploring, pick a move, then "Your adventure is ready!" with the open door and "Let's explore".
- The launch video is no longer part of the flow (the file is kept).
- Hub redesigned: greeting, three big cards, a movement-mission button; mode switch, stars, Meadow, sticker book and grown-ups are round buttons in the top bar.
- SPOT redesigned: "Your next clue" tag, a big clue headline, real example pictures, Take a photo / Choose a photo buttons, and a "Look closer" reveal on its own background.
- PLAY, EXPLORE and movement missions use the new top bar and step dots.
- Backgrounds for outdoor, indoor and "look closer" are drawn in code and replaced automatically when generated artwork is added.
- New helper scripts to prepare AI artwork: `tool/prepare_art.py`, `tool/slice_sticker_sheet.py`, `tool/make_icons.py`.
- Colours updated to the reference palette; contrast tests still pass.

## 1.0.0 – UI polish and release preparation

### Look and feel
- One chunky button style (with a pressed "lip") used everywhere.
- Cards have a soft cream outline and a warm brown shadow.
- Fade-and-zoom screen changes replace the heavier default transition.
- Hub: cards float in one by one, gently bob, and have slots for illustrated art; Vee waves beside the title.
- PLAY: stages slide and fade into each other, with progress dots instead of "3/10".
- Vee breathes while idle, thinks during puzzles, is surprised at surprises (extra poses are optional artwork).
- Star counter counts up and pulses; reward screen has a turning sunburst and a star count-up.
- Friendly Vee loading screen and error screens.
- Illustrated item icons (optional artwork) replace emoji in puzzles, EXPLORE and the sticker book.
- Pointer cursor and hover lift on the web; text sizes raised in several places.

### Production
- Optional artwork never breaks the game: missing files fall back to the old art.
- SPOT photos are smaller (768 px) for quicker identification.
- Release builds show a kind message instead of a grey error box.
- Landscape lock for Android and iOS, icon builder, sticker-sheet slicer.
- Publishing guide, asset prompt guide and privacy policy template.
- Version set to 1.0.0+1.

## Polish and performance release

### Bugs fixed
- PLAY "The Treasure That Moved" could never be finished (the answer, Rock, was never offered). Puzzle answers are now always among the options, and a test checks every story.
- The 2–3 second freeze after a correct EXPLORE drop: the game asked the AI to pick a surprise. It now picks locally and instantly.
- Every EXPLORE tap wrote the whole save file twice and rebuilt the whole app. Saves are now merged and quiet.
- Panels overflowed on short screens. Tall panels now scale down to fit.
- EXPLORE showed a raw ID (for example `tiny_rainbow`) as text. It now shows the surprise's real name.
- The parent gate always asked 3 + 4. It now changes every visit.
- `.env.example` was missing and `.gitignore` would have ignored it.
- AI proxy accepted calls from any website and had no rate limit.

### Speed
- Large images converted to WebP (assets 9.4 MB to 2.7 MB). The shared screen background now loads the small WebP instead of a 1.2 MB PNG.
- Common artwork is preloaded after the first frame.
- Friendly loading screen on the web page.

### Less predictable
- Vee's Meadow (Flame): a tap-reactive world that grows with progress.
- PLAY: three puzzle types chosen per run, 12 stories (was 6) that avoid repeating, and the chosen path decides the surprises and ending.
- EXPLORE: its challenge is now a random puzzle instead of always the same drag.
- Sticker book to collect every discovery.
- Vee reacts (hops, changes pose) to what the child does.
- The main buttons (menus, choices, puzzle cards, movement) squish on touch-down for instant feedback.
- SPOT can be played with "Pick from pictures", with no camera, photo or network.

### Housekeeping
- Deprecated `withOpacity` replaced with `withValues(alpha:)`.
- Web icons, manifest and security headers added.
- New tests: puzzles, surprise picker, debounced saving, the meadow game, and the puzzle widget.
