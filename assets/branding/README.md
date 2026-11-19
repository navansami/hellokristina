# Hello Kristina brand assets

## App icon and favicon (November 2026)

The icons are drawn in code, so they are sharp at every size and match the app's look: warm orange, Kristina as drawn in the app, and a chunky white speech bubble.

- `app-icon-source.png` (1024²): the app icon. Kristina's head and shoulders, smiling, with a heart speech bubble and sparkles on the orange brand gradient. Full-bleed and opaque, because iOS and Android apply their own rounded masks.
- `app-icon-maskable.png` (1024²): the same art with the bubble and sparkles pulled into the central safe circle, for Android launchers that crop icons to a circle.
- `favicon-source.png` (512²): the browser-tab icon. A bold smiling speech bubble on an orange rounded square with transparent corners. A face is unreadable at 16px, so the favicon uses the simpler mark.

To change the icons, edit `tool/brand/render_brand_test.dart`, then run:

```bash
flutter test tool/brand/render_brand_test.dart   # redraws the three masters
python scripts/export-brand-assets.py            # needs Pillow
```

The export writes:
- **Web:** `web/icons/Icon-*.png` and `apple-touch-icon.png`, plus `web/favicon.png`, `web/icons/favicon-32.png` and `web/favicon.ico` (16/32/48).
- **Android:** the `ic_launcher.png` mipmaps.
- **iOS:** every `AppIcon.appiconset` size.

`web/index.html` and `web/manifest.json` link the icons with `?v=2`. Bump that number whenever the icons change, because browsers and home screens cache icons for a long time.

## Sharing card

`social-card-source.png` is still the November 1 artwork: Kristina on cobalt blue, AI-generated with the prompt below. The export turns it into `web/social/hello-kristina-v1.jpg` (1200×630), which Open Graph and Twitter metadata use. If it is redrawn to match the orange icon, save it under a new file name (for example `hello-kristina-v2.jpg`) and update the metadata URLs, because sharing sites cache preview images.

Sharing card prompt (1 November 2026): one wide 1200:630 social preview for Hello Kristina, with Kristina from the chest up, waving, beside a lime speech bubble on cobalt `#2B61A8`. Off-white headline "Hello / Kristina", lime "Learn Serbian.", supporting copy "One playful challenge / at a time." and "hellokristina.app". No third-party brands or flags. Reference: `Kristina.jpg` and the 1 November icon.
