# Hello Kristina brand assets

Created with the built-in image generation tool on 2026-11-01, using root `Kristina.jpg` as the character reference. Brand spelling follows the existing app: **Hello Kristina**.

- `app-icon-source.png`: full-resolution square master, opaque cobalt background, Kristina portrait and lime speech bubble.
- `social-card-source.png`: full-resolution landscape sharing-card master.
- `../../web/social/hello-kristina-v1.jpg`: 1200×630 export, used by Open Graph and Twitter card metadata.
- Web/PWA, favicon, Apple touch, Android launcher, and every existing iOS app-icon size are exported from the square master.

To reproduce the exports, install Pillow and run `python3 scripts/export-brand-assets.py` from the repository. This only resizes/re-encodes the generated art; it does not call an API. Master files are not bundled into the Flutter asset catalog. The finished web assets are copied into the release build from `web/`.

The manifest is linked in `web/index.html`. Sharing tags live in the initial HTML so crawlers can read them without running Flutter, per https://ogp.me/. The image URL is absolute and versioned. These changes need deployment before production sharing uses them; platform preview layout and caching are outside the site's control. Real WhatsApp/Instagram sharing has not been tested locally. Future artwork changes should increment the social image filename and update its metadata URLs.

## App icon generation prompt

Use case: logo-brand. Create one polished square 1024x1024 installed-app icon for the existing Serbian-learning app Hello Kristina. The attached image is the character identity reference: preserve Kristina's peach freckled face, oversized friendly white eyes with brown pupils, dark chocolate asymmetrical swept hair, long hair on viewer left only, small part and low right temple, magenta turtleneck, playful confident smile. Flat clean vector-like illustration, simple bold silhouettes, crisp smooth edges, original friendly educational-app aesthetic. Full-bleed solid rich cobalt blue #2B61A8 background all the way to the square edges, NO rounded square frame, NO outer padding, NO transparency. A close-up centered head and small upper shoulders; entire face and hair silhouette comfortably within central 74% of the square so circular home-screen masks preserve the character. Face large and readable at 48px. Small bright lime speech-bubble accent near the upper right of her head, no writing inside, subordinate to the portrait. Modern, charming, exceptionally clean. NO text, NO letters, NO flags, NO logos from other apps, NO gradients, NO 3D, NO shadows, NO mockup, NO multiple variations, NO watermarks. Output only the final square icon artwork.

Reference: `Kristina.jpg`. Transparent background: false.

## Sharing card generation prompt

Use case: ads-marketing. Create one finished wide landscape social link-preview card for the Serbian learning app Hello Kristina. Target aspect ratio 1200:630 (1.905:1); render 1536x806 or similar wide composition. Image 1 is Kristina's original character reference; Image 2 is the approved app icon establishing the matching brand direction. Preserve her face, freckles, oversized white eyes with brown pupils, asymmetrical swept dark-brown hair with the long hair on viewer left, magenta turtleneck, and cheeky warm smile. Match the cobalt blue background, peach/magenta character colors, and electric lime speech bubble. Clean bold flat vector-like illustration, polished vibrant educational brand, lots of breathing room, no photorealism. Layout designed for readable link previews: large strong off-white rounded sans-serif headline on left in two lines exactly 'Hello' then 'Kristina'; below it a clear lime text line exactly 'Learn Serbian.'; under that smaller off-white supporting copy in two short lines exactly 'One playful challenge' then 'at a time.' Bottom left small text exactly 'hellokristina.app'. On right Kristina from the chest upward smiling and waving one hand, very large and lovable, with one lime empty speech bubble above shoulder. All important artwork and text kept at least 7% from the edges. Background cobalt blue #2B61A8, sparse subtle blue abstract conversation shapes at edges only. High contrast, no busy patterns, no fake UI, no buttons, no phone mockup, no watermark, no third-party brand, no flag, no extra copy. Exact brand spelling is Hello Kristina (not Kristine). Output only the final finished landscape artwork, not a sheet of alternatives.

References: `Kristina.jpg` and the generated square icon. Transparent background: false.
