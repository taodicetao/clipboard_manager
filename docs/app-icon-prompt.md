# App icon — generation prompt (macOS 27 Golden Gate style)

## Workflow

1. Generate a **full-bleed square** image (no rounded corners, no shadow, no transparent
   or checkerboard background — the artwork must run edge to edge). 1024 px or larger.
2. Run `scripts/make-app-icon.swift path/to/image.png` — it trims any frame the generator
   added, applies Apple's icon shape (1024 canvas, 824 px rounded square, 22.37 % corner
   radius, transparent outside) and writes all ten sizes plus `Contents.json` into
   `ClipboardManager/Assets.xcassets/AppIcon.appiconset`.
3. `scripts/install.sh` to see it in the Dock and menu bar.

Generators cannot produce real transparency: a "transparent background" request comes back
as a baked-in checkerboard inside a JPEG, and the squircle they draw never matches Apple's
mask. Ask for full-bleed artwork and let the script do the shape.

## Main prompt

```
App icon artwork for macOS 27, full-bleed square, edge to edge, no rounded corners, no
border, no frame, no drop shadow, no background grid. Style: Apple's redesigned system
icons — one bold glass object on a vivid matte gradient, flat front view, soft studio
light, no bevel, no gloss, no 3D tilt. Background: smooth gradient from electric blue at
the top-left to deep indigo at the bottom-right. Subject: a single clipboard filling
about 70 % of the height, centered. The board is bright white frosted glass at 85 %
opacity with softly rounded corners and a thin luminous edge. A coral-orange clip sits
centered on its top edge, clearly visible, with a small round hole. On the board, three
short rounded text lines in pale blue-gray at 40 % opacity, left-aligned, suggesting
copied text. Behind the board one identical sheet peeks out, offset a little up and to
the right, slightly more transparent — the previous copy. A gentle soft shadow under the
board onto the background. Clean geometric shapes, even margins, readable at 16 px. No
letters, no words, no hands, no photo elements, no extra objects. Vector-clean render,
1024×1024, high detail.
```

Why this version: the dark indigo attempt turned into a glossy plastic button, and the
all-glass stack lost the clipboard identity at 16 px because the clip was glass on glass.
This one keeps the light-on-vivid Apple look but gives the silhouette one contrasting
anchor (the coral clip), a more opaque board so it separates from the violet bottom, and
faint lines that say "text" without becoming clutter.

## Variations

- **Cooler** — background `sky blue to royal blue`, clip `navy` instead of coral.
- **Two-tone Apple** — background `white to pale gray`, board `deep blue glass`, clip
  `white`; the inverted look used by Apple's productivity icons.
- **No lines** if the text lines render as noise at small sizes — drop the sentence
  about text lines.
- **Dark Mode / tinted variant** — background `graphite to near-black`, board `smoked
  white glass at 60 % opacity`, clip `coral`.

## Negative prompt

```
checkerboard, transparency grid, rounded corners, squircle, icon frame, border, drop
shadow outside the artwork, bevel, glossy plastic button, chrome, dark navy background,
3D isometric perspective, text, letters, watermark, multiple icons, photo, paper
texture, blurry, low contrast
```

## Checklist before shipping

- Zoom to 16 px and 32 px: the clipboard silhouette must still read.
- The glass must be lighter than the background — Apple's icons are light subjects on
  saturated backgrounds, not dark buttons.
- If the generator still adds a frame, `make-app-icon.swift` trims it, but the artwork
  inside will be small — regenerate with "full-bleed, edge to edge" repeated.
- Optional polish: rebuild the final artwork as real layers in Apple's **Icon Composer**
  (ships with Xcode) for true Liquid Glass behavior in the Dock and Launchpad.
