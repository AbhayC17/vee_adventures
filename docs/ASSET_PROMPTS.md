# Artwork to create for the new look (and the prompts to make it)

> **Status: delivered.** All 15 pieces of artwork described below have been created and are in
> the project (as WebP, processed with `tool/prepare_art.py` and `tool/slice_sticker_sheet.py`).
> Keep this guide for adding or redoing art later. Tools need `pip install pillow numpy scipy`.
> Notes from the real files: the backgrounds are 1672x941 (not upscaled), Vee's poses are
> 890x1000 on one shared canvas, and the doors are about 1100 px wide.


The new design (cream pages, flat storybook illustrations, deep-teal pill
buttons) already works with **no new files**: the backgrounds are drawn in code
and the old Vee pictures fill in. Adding the artwork below makes it look like
your reference screens. Every file is optional and the game falls back to the
current picture if it is missing, so you can add them in any order.

## The 15 files

| # | File (exact name) | Size | What it is | Priority |
|---|---|---|---|---|
| 1 | `assets/scenes/bg_meadow.webp` | 1920×1080 | Outdoor background | 1 |
| 2 | `assets/scenes/bg_indoor.webp` | 1920×1080 | Indoor background | 1 |
| 3 | `assets/scenes/bg_closeup.webp` | 1920×1080 | "Look closer" background | 2 |
| 4 | `assets/scenes/door_closed.webp` | 900×1200, transparent | Closed garden door | 1 |
| 5 | `assets/scenes/door_open.webp` | 900×1200, transparent | Open door, sunrise inside | 1 |
| 6 | `assets/vee/vee_happy_idle.webp` | 1000×1200, transparent | Vee standing (replaces old) | 1 |
| 7 | `assets/vee/vee_encourage.webp` | 1000×1200, transparent | Vee thumbs-up (replaces old) | 1 |
| 8 | `assets/vee/vee_celebration.webp` | 1000×1200, transparent | Vee cheering (replaces old) | 1 |
| 9 | `assets/vee/vee_wave.webp` | 1000×1200, transparent | Vee waving / presenting | 1 |
| 10 | `assets/vee/vee_spot.webp` | 1000×1200, transparent | Vee crouching with magnifier | 1 |
| 11 | `assets/vee/vee_thinking.webp` | 1000×1200, transparent | Vee thinking | 2 |
| 12 | `assets/vee/vee_surprised.webp` | 1000×1200, transparent | Vee amazed | 2 |
| 13 | `assets/vee/vee_sleepy.webp` | 1000×1200, transparent | Vee yawning (error screens) | 2 |
| 14 | 20 item icons from **one sticker sheet** → `assets/items/*.webp` | 512×512 each | Replaces emoji | 1 |
| 15 | `branding/app_icon_1024.png` | 1024×1024, no transparency | App icon | 2 |

**Fastest good result:** make the Priority 1 items (about 10 pictures). Priority 2
can follow later.

---

## How to get a consistent set from an AI tool

1. **Use your four reference screens as the style reference.** Midjourney:
   upload them and add `--sref <image URLs>`. ChatGPT / Gemini / Firefly /
   Ideogram / Leonardo: attach the pictures and say "match this art style
   exactly: same flat vector look, same colours, same character".
2. **Make Vee first.** Generate pose #6 until he looks right, then attach that
   picture as the **character reference** for every other pose (Midjourney
   `--cref <url>`, Leonardo "Character Reference", ChatGPT/Gemini: "keep this
   exact character, same face, outfit and proportions").
3. **Generate 4 variations, pick the best, and zoom out to thumbnail size** to
   check it reads clearly. Children see these small.
4. Do not ask for text in any picture. Words are drawn by the game.
5. Run the preparation commands at the end of this file.

### Reusable prompt blocks (paste these inside each prompt)

**[STYLE]**

> Flat vector storybook illustration for a preschool app, soft rounded shapes,
> clean smooth edges with no black outlines, subtle two-tone shading and gentle
> gradients only, cheerful and calm, uncluttered, high detail but easy to read.
> Colour palette: warm cream #FDF6E6, deep teal #0F5F55, forest green #2F7F5B,
> leaf green #5BA14F and #7DB85A, sunny yellow #FFC62E, soft coral #E65A3C,
> pale sky blue #DDEBF0, sand path #F4DFA8.

**[VEE]**

> Vee, a cute chubby young tiger cub mascot: big round head, small round ears
> with dark brown inside, bright orange fur with bold dark-brown stripes, white
> muzzle and chest, big glossy black eyes with white highlights, small black
> nose, rosy open smile. He wears a royal-blue baseball cap with a golden
> paw-print badge, a yellow zip jacket with blue trim over a white t-shirt,
> blue cargo shorts, blue-and-yellow sneakers and a small blue backpack. Striped
> tail. Friendly, safe and gentle, never scary.

**[CUTOUT]** (for anything that must be transparent)

> Solid flat magenta #FF00FF background filling the whole picture, no ground,
> no shadow, no gradient and no other objects, so the background can be removed.
> The whole subject is fully inside the frame with space around it.

**[SAFE ZONE]** (for backgrounds, very important)

> This is a background for a game screen where headlines, buttons and a
> character will be placed on top. Keep the middle and right of the picture
> (about 55% of the width, from 15% to 75% of the height) as calm, empty warm
> cream #FDF6E6 with no objects. Keep the top 12% very light and empty. Put the
> scenery along the edges and bottom only. No characters, no animals, no text,
> no logos, no borders, no frame.

**Negative prompt** (Midjourney `--no`, or "avoid:" in other tools):
`text, letters, watermark, signature, black outlines, photorealistic, 3d render,
glossy plastic, scary, dark, clutter, frame, border, extra limbs, extra fingers`

---

## 1–3. Backgrounds (16:9, e.g. `--ar 16:9`)

### 1. Outdoor meadow → `bg_meadow.webp`

> [STYLE] A wide storybook meadow scene. A big round leafy tree with a brown
> trunk fills the far left edge and a smaller tree the far right edge. Soft pale
> green rolling hills (#B4D8AC and #A2CF99) along the bottom third, a sandy path
> winding from the bottom centre to the right side, dense dark-green bushes
> (#1F7A56, #2F8F5E) framing the bottom-left and bottom-right corners with
> tiny white and coral flowers. A pale yellow sun with a soft glow at the top
> right and two small pale-blue clouds. [SAFE ZONE]

### 2. Indoor room → `bg_indoor.webp`

> [STYLE] A cosy children's living-room corner, flat storybook style. A large
> arched window with teal frame and coral curtains on the far left showing a
> pale-blue sky with a little sun. A wooden bookshelf with colourful books and a
> potted plant on the far right edge. Warm sand-coloured wooden floor along the
> bottom 20% with soft plank lines and a round coral-and-yellow rug at the
> bottom centre. Soft cream walls. A few leafy plants in the bottom-left
> corner. [SAFE ZONE]

### 3. Look closer → `bg_closeup.webp`

> [STYLE] A soft background for a "look closer" moment. A large pale-green
> organic blob shape (#E1EEDA) filling the left half of the picture with a
> smaller lighter blob inside it (leave both completely empty, a picture will be
> placed here). Big dark-green leaves curling in from the top-left, bottom-left
> and right edges, a few tiny floating leaves and three small yellow sparkle
> dashes. A small green hill with a sandy path and one coral flower in the
> bottom-right corner. The right half stays calm warm cream. No characters, no
> text, no frame, top 12% light and empty.

Then run (from the project root):
`python tool/prepare_art.py scene raw.png assets/scenes/bg_meadow.webp`
(same for the other two).

---

## 4–5. The door (portrait 3:4)

### 4. Closed door → `door_closed.webp`

> [STYLE] A fairytale arched garden door, front view, centred. A deep
> forest-green wooden door with vertical planks and a rounded top, inside a
> thick arch of leafy vines in several greens. A golden compass-star emblem (a
> four-point star inside a thin circle with tiny tick marks) in the middle of
> the door, a small round golden knob on the right, a few white flowers and leafy
> bushes at the base on both sides, a short strip of grass. [CUTOUT]

### 5. Open door → `door_open.webp`

> [STYLE] The same fairytale arched garden doorway as a front view, but standing
> open. A dark teal-green stone arch with a light-green leaf-shaped gem on top
> and small leaf ornaments on the left side. The wooden door is swung open to
> the right so we see its edge, with a golden diamond-star emblem and golden
> knob. Through the archway: a glowing golden-yellow sunrise over rolling green
> hills, a winding sandy path leading into the distance and tiny white clouds.
> A small green bush at the base. [CUTOUT]

Then: `python tool/prepare_art.py cutout raw.png assets/scenes/door_open.webp --size 900x1200`

---

## 6–13. Vee poses (portrait 5:6)

Every prompt is: **[VEE] + pose + [STYLE] + [CUTOUT]**. Full body, centred,
facing slightly toward the viewer, the whole character in frame, the same
size and proportions every time.

| # | File | Pose to add after [VEE] |
|---|---|---|
| 6 | `vee_happy_idle` | Standing relaxed with weight on one leg, both arms loosely at his sides, a big friendly smile, head tilted slightly. |
| 7 | `vee_encourage` | Standing, one arm stretched out giving a big thumbs-up, the other hand on his hip, a warm encouraging grin, happy eyes. |
| 8 | `vee_celebration` | Jumping in the air with both arms raised high, mouth wide open laughing, tail swishing, a few small flat yellow sparkle dashes around him. |
| 9 | `vee_wave` | Standing, one hand raised high waving hello, the other arm held out with an open palm as if presenting something, a bright welcoming smile. |
| 10 | `vee_spot` | Crouching low on one knee, holding a large magnifying glass (teal handle, pale-blue lens with a white glare) up to one eye, the other hand resting on his knee, excited curious expression, backpack visible, tail curling behind. |
| 11 | `vee_thinking` | Standing, one paw resting on his chin, head tilted, eyes looking up and to the side, a small curious smile. |
| 12 | `vee_surprised` | Eyes wide, mouth open in a happy "wow", both hands raised beside his cheeks, a couple of small flat yellow sparkle dashes beside him. |
| 13 | `vee_sleepy` | Gentle and cosy: eyes half closed, a small yawn, one paw rubbing an eye, hugging a small blue pillow, cap slightly tilted. Warm and calm, nothing sad. |

Complete example (pose #9):

> Vee, a cute chubby young tiger cub mascot: big round head, small round ears
> with dark brown inside, bright orange fur with bold dark-brown stripes, white
> muzzle and chest, big glossy black eyes with white highlights, small black
> nose, rosy open smile. He wears a royal-blue baseball cap with a golden
> paw-print badge, a yellow zip jacket with blue trim over a white t-shirt, blue
> cargo shorts, blue-and-yellow sneakers and a small blue backpack. Striped
> tail. Pose: standing, one hand raised high waving hello, the other arm held
> out with an open palm as if presenting something, a bright welcoming smile.
> Full body, centred, facing slightly toward the viewer. [STYLE] [CUTOUT]
> Portrait 5:6.

Then, for each: `python tool/prepare_art.py cutout raw.png assets/vee/vee_wave.webp`
(default size is 1000×1200, bottom-aligned).

Replacing `vee_happy_idle`, `vee_encourage` and `vee_celebration` keeps their
file names, so nothing else needs to change.

---

## 14. Item sticker sheet (20 icons)

> [STYLE] A sticker sheet of 20 separate simple icons for a children's game,
> arranged in a neat grid of 5 columns and 4 rows with generous empty space
> between every icon, nothing touching or overlapping, each icon centred in its
> own cell. Each icon is a friendly flat vector object with soft rounded shapes,
> bright colours, a small white highlight and no outline. Reading left to right,
> top to bottom: Row 1: a red apple with a green leaf, a yellow banana, a red
> tomato with a green stem, an orange carrot with green top, a pink flower with
> a yellow centre. Row 2: a round leafy green tree with a brown trunk, a single
> green leaf with visible veins, a colourful butterfly, a cute small blue bird,
> a grey rock. Row 3: a blue water drop, a toothbrush with blue handle and
> toothpaste, a bar of soap with a few bubbles, a round hand mirror, a closed
> blue storybook. Row 4: a small table lamp, a red balloon with a string, a
> white dinner plate with a teal rim, a cup with a straw, a teddy bear. Solid
> flat magenta #FF00FF background everywhere, no shadows, no text.

If the AI cannot keep the order, make them one at a time with the same style
prompt and the same background, then name each result after its item (`apple`,
`banana`, `tomato`, `carrot`, `flower`, `tree`, `leaf`, `butterfly`, `bird`,
`rock`, `water`, `toothbrush`, `soap`, `mirror`, `book`, `lamp`, `balloon`,
`plate`, `cup`, `toy`) and run
`python tool/prepare_art.py cutout apple_raw.png assets/items/apple.webp --size 512x512 --align center`.

For the full sheet run: `python tool/slice_sticker_sheet.py sheet.png`
(finds each icon, removes the magenta, centres it and writes the 20 files).

---

## 15. App icon

> [STYLE] A square app icon. Vee's friendly smiling face and shoulders in his
> blue cap, large and centred, looking at the viewer, with a soft sunny
> background that fades from sky blue (#DDEBF0) to warm cream, a few tiny golden
> sparkle dashes. Keep Vee at least 12% away from every edge so rounded corners
> never cut him off. Full-bleed square, no transparency, no text, no border.
> 1:1.

Save as `branding/app_icon_1024.png`, then run
`python tool/make_icons.py branding/app_icon_1024.png`.

---

## After adding files

1. Make sure the files are in the folders named above (they already exist).
2. `flutter clean && flutter pub get && flutter run -d chrome --release`
3. Look at every screen at normal size. If a headline sits on top of a busy part
   of a background, regenerate that background with a stronger [SAFE ZONE].
4. Do not rename files. The game finds them by these exact names.
5. Update `"dimensions"` for `background.main` in `assets/data/asset_registry.json`
   only if you replace the old `game_background.webp` (it is no longer used by
   the new design and can be left alone).
