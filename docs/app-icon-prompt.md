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
border, no frame, no drop shadow, no background grid. Style: Apple's 2025 redesigned
system icons (Finder, Notes, Reminders) — soft frosted-glass layers on a bright matte
gradient, flat front view, no bevel, no glossy plastic, no 3D perspective. Background:
smooth gradient from sky blue at the top to vivid violet at the bottom. Subject: one
large white translucent glass clipboard, centered, filling about 65 % of the height, a
small rounded clip at the top; behind it two identical glass sheets offset a little to
the upper right, like a stack of things copied. Glass is milky white with 70 % opacity,
soft inner glow, a thin brighter edge along the top of each layer, gentle shadow where a
layer overlaps the one below. Clean geometric shapes, wide even margins, readable at
16 px. No text, no letters, no icons inside the clipboard, no paper lines, no hands,
no photo elements. Vector-clean render, 1024×1024, high detail.
```

## Variations

- **Cool monochrome** — background `pale blue to deep blue`, glass `white`; the most
  Apple-like, and it stays readable next to Finder and Safari in the Dock.
- **Warm accent** — add `a small coral clip on the clipboard` for one point of color.
- **Dark Mode / tinted variant** — background `graphite to near-black`, glass
  `smoked white at 60 % opacity`, edges `lit pale blue`.
- **Simpler silhouette** if the stack reads as noise at small sizes — `a single glass
  clipboard, no sheets behind it`.

## Negative prompt

```
checkerboard, transparency grid, rounded corners, squircle, icon frame, border, drop
shadow outside the artwork, bevel, glossy button, chrome, dark navy, 3D isometric
perspective, text, letters, watermark, multiple icons, photo, paper texture, blurry
```

## Checklist before shipping

- Zoom to 16 px and 32 px: the clipboard silhouette must still read.
- The glass must be lighter than the background — Apple's icons are light subjects on
  saturated backgrounds, not dark buttons.
- If the generator still adds a frame, `make-app-icon.swift` trims it, but the artwork
  inside will be small — regenerate with "full-bleed, edge to edge" repeated.
- Optional polish: rebuild the final artwork as real layers in Apple's **Icon Composer**
  (ships with Xcode) for true Liquid Glass behavior in the Dock and Launchpad.
