"""Generates every brand and store image for LumaShield.

Run from the repository root:

    python3 tool/brand/generate_assets.py

Outputs into deploy/playstore/graphics/ and refreshes the Android launcher
PNGs. Requires Pillow (`pip install pillow`).

The mark is drawn with the same geometry as the Android vector icon
(android/app/src/main/res/drawable/ic_launcher_foreground.xml) so the launcher,
the store listing and the README all show the same logo.
"""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
RES = ROOT / "android/app/src/main/res"
OUT = ROOT / "deploy/playstore/graphics"

SS = 4  # supersampling for smooth edges
NAVY_TOP = (16, 26, 46)
NAVY_BOTTOM = (7, 11, 20)
AMBER_LIGHT = (255, 201, 120)
AMBER = (240, 164, 74)
AMBER_DARK = (217, 118, 43)

FONT_DIR = pathlib.Path("/usr/share/fonts/truetype/dejavu")


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def quad(p0, p1, p2, steps=48):
    out = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        out.append((x, y))
    return out


def shield_polygon(w, h, scale=1.0, dy=0.0):
    def p(x, y):
        return ((0.5 + (x - 0.5) * scale) * w, (0.5 + (y - 0.5) * scale + dy) * h)

    pts = [p(0.265, 0.165), p(0.735, 0.165), p(0.735, 0.545)]
    pts += quad(p(0.735, 0.545), p(0.705, 0.760), p(0.5, 0.885))[1:]
    pts += quad(p(0.5, 0.885), p(0.295, 0.760), p(0.265, 0.545))[1:]
    return pts


def draw_gradient(img, top=NAVY_TOP, bottom=NAVY_BOTTOM, radius_ratio=0.0):
    w, h = img.size
    grad = Image.new("RGB", (1, h))
    gd = ImageDraw.Draw(grad)
    for y in range(h):
        gd.point((0, y), lerp(top, bottom, y / max(1, h - 1)))
    grad = grad.resize((w, h))
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    if radius_ratio > 0:
        md.rounded_rectangle(
            [0, 0, w - 1, h - 1], radius=int(min(w, h) * radius_ratio), fill=255
        )
    else:
        md.rectangle([0, 0, w - 1, h - 1], fill=255)
    img.paste(grad, (0, 0), mask)
    return img


def draw_mark(img, scale=1.0, dy=0.0, monochrome=False):
    w, h = img.size
    poly = shield_polygon(w, h, scale, dy)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    # A light blur plus threshold rounds the corners like the vector icon.
    mask = mask.filter(ImageFilter.GaussianBlur(w * 0.012)).point(
        lambda v: 255 if v > 140 else 0
    )

    if monochrome:
        layer = Image.new("RGBA", (w, h), (255, 255, 255, 0))
        layer.paste(Image.new("RGBA", (w, h), (255, 255, 255, 255)), (0, 0), mask)
    else:
        grad = Image.new("RGB", (1, h))
        gd = ImageDraw.Draw(grad)
        for y in range(h):
            t = y / max(1, h - 1)
            color = (
                lerp(AMBER_LIGHT, AMBER, t / 0.55)
                if t < 0.55
                else lerp(AMBER, AMBER_DARK, (t - 0.55) / 0.45)
            )
            gd.point((0, y), color)
        grad = grad.resize((w, h))
        layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        layer.paste(grad.convert("RGBA"), (0, 0), mask)

    d = ImageDraw.Draw(layer)

    def p(x, y):
        return ((0.5 + (x - 0.5) * scale) * w, (0.5 + (y - 0.5) * scale + dy) * h)

    upper = quad(p(0.320, 0.520), p(0.5, 0.382), p(0.680, 0.520), 40)
    lower = quad(p(0.680, 0.520), p(0.5, 0.658), p(0.320, 0.520), 40)
    cx, cy = p(0.5, 0.520)
    r = 0.062 * w * scale
    r2 = 0.026 * w * scale

    if monochrome:
        # Eye and pupil are punched out so the silhouette still reads as an eye.
        d.polygon(upper + lower, fill=(255, 255, 255, 0))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 255))
        d.ellipse([cx - r2, cy - r2, cx + r2, cy + r2], fill=(255, 255, 255, 0))
    else:
        d.polygon(upper + lower, fill=(10, 16, 32, 255))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(243, 201, 138, 255))
        d.ellipse([cx - r2, cy - r2, cx + r2, cy + r2], fill=(12, 20, 38, 255))

    img.paste(layer, (0, 0), layer)


def app_icon(size: int, rounded: bool = False) -> Image.Image:
    w = size * SS
    img = Image.new("RGB", (w, w), NAVY_TOP)
    draw_gradient(img, radius_ratio=0.22 if rounded else 0.0)
    draw_mark(img, scale=0.92, dy=0.01)
    img = img.resize((size, size), Image.LANCZOS)
    if rounded:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, size - 1, size - 1], radius=int(size * 0.22), fill=255
        )
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask)
        return out
    return img


def circular(size: int) -> Image.Image:
    w = size * SS
    img = Image.new("RGB", (w, w), NAVY_TOP)
    draw_gradient(img)
    draw_mark(img, scale=0.92, dy=0.01)
    img = img.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def adaptive_foreground(size: int) -> Image.Image:
    """108dp layer: the mark occupies the inner 66% safe zone."""
    w = size * SS
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw_mark(img, scale=0.66, dy=0.0)
    return img.resize((size, size), Image.LANCZOS)


def adaptive_background(size: int) -> Image.Image:
    w = size * SS
    img = Image.new("RGB", (w, w), NAVY_TOP)
    draw_gradient(img)
    return img.resize((size, size), Image.LANCZOS)


def monochrome(size: int) -> Image.Image:
    w = size * SS
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    draw_mark(img, scale=0.66, dy=0.0, monochrome=True)
    return img.resize((size, size), Image.LANCZOS)



def fit_font(draw, text, max_width, path, start_size, min_size=18):
    """Largest font size at which `text` still fits `max_width`."""
    size = start_size
    while size > min_size:
        font = ImageFont.truetype(str(path), size)
        if draw.textlength(text, font=font) <= max_width:
            return font
        size -= 2
    return ImageFont.truetype(str(path), min_size)


def feature_graphic(w: int = 1024, h: int = 500) -> Image.Image:
    """1024x500 Play feature graphic. Text is measured so it never clips."""
    fw, fh = w * 2, h * 2
    feat = Image.new("RGB", (fw, fh), NAVY_TOP)
    draw_gradient(feat, (18, 30, 52), (6, 10, 18))
    glow = Image.new("RGB", (fw, fh), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([fw * 0.45, -fh * 0.6, fw * 1.15, fh * 1.5], fill=(58, 36, 14))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    feat = Image.blend(feat, Image.blend(feat, glow, 0.55), 0.55)

    mark_size = int(fh * 0.56)
    mark = Image.new("RGBA", (mark_size, mark_size), (0, 0, 0, 0))
    draw_mark(mark, scale=0.95)
    mark_pos = (int(fw * 0.07), int((fh - mark_size) / 2))
    feat.paste(mark, mark_pos, mark)

    text_x = mark_pos[0] + mark_size + int(fw * 0.035)
    max_width = fw - text_x - int(fw * 0.05)
    d = ImageDraw.Draw(feat)
    bold = FONT_DIR / "DejaVuSans-Bold.ttf"
    regular = FONT_DIR / "DejaVuSans.ttf"

    title = "LumaShield"
    tagline = "Blue light filter & eye care"
    blurb = "Warm, glare free screens from dusk to dawn"

    title_font = fit_font(d, title, max_width, bold, 150)
    tagline_font = fit_font(d, tagline, max_width, regular, 62)
    blurb_font = fit_font(d, blurb, max_width, regular, 46)

    title_h = title_font.size
    tagline_h = tagline_font.size
    blurb_h = blurb_font.size
    gap = int(fh * 0.035)
    total = title_h + tagline_h + blurb_h + gap * 2
    y = (fh - total) / 2

    d.text((text_x, y), title, font=title_font, fill=(246, 249, 255))
    y += title_h + gap
    d.text((text_x, y), tagline, font=tagline_font, fill=(240, 178, 110))
    y += tagline_h + gap
    d.text((text_x, y), blurb, font=blurb_font, fill=(154, 168, 194))
    return feat.resize((w, h), Image.LANCZOS)


def lockup(w: int = 1200, h: int = 400) -> Image.Image:
    """Transparent logo lockup for press, the website and social posts."""
    fw, fh = w * 2, h * 2
    img = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    mark_size = int(fh * 0.58)
    mark = Image.new("RGBA", (mark_size, mark_size), (0, 0, 0, 0))
    draw_mark(mark, scale=0.95)
    mark_pos = (int(fw * 0.05), int((fh - mark_size) / 2))
    img.paste(mark, mark_pos, mark)

    d = ImageDraw.Draw(img)
    text_x = mark_pos[0] + mark_size + int(fw * 0.03)
    max_width = fw - text_x - int(fw * 0.05)
    bold = FONT_DIR / "DejaVuSans-Bold.ttf"
    regular = FONT_DIR / "DejaVuSans.ttf"

    title_font = fit_font(d, "LumaShield", max_width, bold, 170)
    tagline_font = fit_font(d, "Blue light filter & eye care", max_width, regular, 62)
    gap = int(fh * 0.04)
    total = title_font.size + tagline_font.size + gap
    y = (fh - total) / 2

    d.text((text_x, y), "LumaShield", font=title_font, fill=(246, 249, 255, 255))
    d.text(
        (text_x, y + title_font.size + gap),
        "Blue light filter & eye care",
        font=tagline_font,
        fill=(240, 178, 110, 255),
    )
    return img.resize((w, h), Image.LANCZOS)


def launcher_pngs():
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in sizes.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        app_icon(size).save(folder / "ic_launcher.png")
        circular(size).save(folder / "ic_launcher_round.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    adaptive_dir = OUT / "adaptive-icon"
    adaptive_dir.mkdir(parents=True, exist_ok=True)

    app_icon(512).save(OUT / "app-icon-512.png")
    circular(512).save(OUT / "app-icon-round-512.png")
    app_icon(1024).save(OUT / "app-icon-1024.png")
    feature_graphic().save(OUT / "feature-graphic-1024x500.png")
    lockup().save(OUT / "logo-lockup-1200x400.png")

    adaptive_foreground(432).save(adaptive_dir / "foreground-432.png")
    adaptive_background(432).save(adaptive_dir / "background-432.png")
    monochrome(432).save(adaptive_dir / "monochrome-432.png")

    launcher_pngs()
    print("brand assets written to", OUT.relative_to(ROOT))
    print("launcher PNGs refreshed in", RES.relative_to(ROOT))


if __name__ == "__main__":
    main()
