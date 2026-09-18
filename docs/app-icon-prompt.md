# App icon — generation prompt (macOS 26 style)

Target: 1024×1024 PNG, opaque squircle on a transparent canvas. Drop the result into
`ClipboardManager/Assets.xcassets/AppIcon.appiconset/` as the largest PNG — the build
script picks the biggest file there and generates every size.

## Main prompt

```
macOS Tahoe app icon, single rounded-square squircle centered on a transparent
background, Apple Liquid Glass design language. Subject: a clipboard with three
stacked translucent cards fanning out from it, the top card slightly lifted — the
history of things copied. Material: layered frosted glass with soft internal light,
subtle specular rim highlights along the top edges, gentle refraction where layers
overlap, thin luminous edge. Palette: deep indigo-to-teal gradient background inside
the squircle, cards in white glass with a faint cyan tint, one warm coral accent on the
clipboard clip. Lighting from top-left, soft ambient occlusion under each layer,
smooth studio look, no harsh shadows. Minimal, geometric, symmetrical composition,
generous margins, shapes readable at 16 px. No text, no letters, no wordmark, no
paper texture, no photorealistic clutter. Ultra clean vector-like render, 1024×1024,
high detail.
```

## Variations

- **Monochrome glass** — replace the palette line with: `single-hue translucent blue
  glass, white highlights only, no warm accent` (closest to Apple's own utilities).
- **Dark variant** for Dark Mode / tinted icons — `graphite glass background, cards in
  smoked glass, edges lit in pale blue`.
- **Flatter fallback** if the generator over-renders — add `flat layered paper-cut
  style with soft drop shadows, still glass-like translucency, less gloss`.

## Negative prompt (for generators that support one)

```
text, letters, watermark, logo, multiple icons, 3D perspective tilt, photo,
skeuomorphic wood or leather, drop shadow outside the squircle, background scene,
border, frame, blurry, low resolution
```

## Checklist before shipping

- Read at 16 px and 32 px: the clipboard silhouette must still be recognizable.
- Squircle corner radius ≈ 22.37 % of the side (Apple's mask); the generator's shape is
  masked by macOS anyway, so keep the artwork inside the safe area.
- Prefer a version with fewer layers if the glass highlights turn into noise at 32 px.
- Optional polish: rebuild the final artwork as real layers in Apple's **Icon Composer**
  (ships with Xcode 26) to get true Liquid Glass behavior in the Dock and Launchpad.
