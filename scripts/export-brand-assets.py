#!/usr/bin/env python3
"""Export install icons and the sharing card. Requires Pillow (pip install Pillow)."""
import json
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / 'assets/branding'


def png(image, relative, size):
    target = ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(target, optimize=True)


def main():
    icon = Image.open(BRANDING / 'app-icon-source.png').convert('RGB')
    assert icon.width == icon.height, 'The app icon source must be square'
    for size in (192, 512):
        png(icon, f'web/icons/Icon-{size}.png', size)
        # The face sits inside the central circle; the outer shoulders may crop.
        png(icon, f'web/icons/Icon-maskable-{size}.png', size)
    png(icon, 'web/icons/apple-touch-icon.png', 180)
    png(icon, 'web/favicon.png', 48)
    icon.save(ROOT / 'web/favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)])

    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        png(icon, f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)

    ios_dir = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
    catalog = json.loads((ROOT / ios_dir / 'Contents.json').read_text())
    for entry in catalog['images']:
        points = float(entry['size'].split('x')[0])
        scale = float(entry['scale'].removesuffix('x'))
        png(icon, ios_dir / entry['filename'], round(points * scale))

    card = Image.open(BRANDING / 'social-card-source.png').convert('RGB')
    target = ROOT / 'web/social/hello-kristina-v1.jpg'
    target.parent.mkdir(parents=True, exist_ok=True)
    ImageOps.fit(card, (1200, 630), method=Image.Resampling.LANCZOS).save(
        target, quality=90, optimize=True, progressive=True)
    print('Exported web, Android, and iOS icons and 1200×630 social card.')


if __name__ == '__main__':
    main()
