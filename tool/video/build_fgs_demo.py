"""Builds the foreground service demo video from the app's own screenshots.

    python3 tool/video/build_fgs_demo.py

Output: deploy/playstore/video/fgs-demo.mp4 (1080x1920, 30 fps, ~30 s).

This is a composed demo, not a device screen recording: the phone screens are the
real widget tree renders from tool/screenshots, and the "other app" is a mock
browser tinted with the same black body maths the filter uses
(android/app/src/main/kotlin/com/lumashield/app/filter/FilterConfig.kt).

Record on a real phone for the strongest Play submission; this file is for the
listing, social posts, and as a fallback if you cannot record.
"""

from __future__ import annotations

import math
import pathlib
import shutil
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
SHOTS = ROOT / "deploy/playstore/graphics/screenshots/phone"
OUT = ROOT / "deploy/playstore/video"
FONT_DIR = pathlib.Path("/usr/share/fonts/truetype/dejavu")

W, H = 1080, 1920
FPS = 30
NAVY = (11, 16, 32)
AMBER = (240, 164, 74)
TEXT = (242, 246, 255)


def kelvin_to_rgb(kelvin: float) -> tuple[int, int, int]:
    """Same approximation as FilterConfig.kelvinToColor."""
    temp = kelvin / 100.0
    red = 255.0 if temp <= 66 else 329.698727446 * ((temp - 60) ** -0.1332047592)
    if temp <= 66:
        green = 99.4708025861 * math.log(temp) - 161.1195681661
    else:
        green = 288.1221695283 * ((temp - 60) ** -0.0755148492)
    if temp >= 66:
        blue = 255.0
    elif temp <= 19:
        blue = 0.0
    else:
        blue = 138.5177312231 * math.log(temp - 10) - 305.0447927307

    def clamp(value: float) -> int:
        return max(0, min(255, int(value)))

    return clamp(red), clamp(green), clamp(blue)


def tint_alpha(intensity: int, kelvin: int) -> float:
    """Mirrors the native overlay: intensity x warmth x 0.72, capped."""
    warmth = max(0.0, min(1.0, (6500 - kelvin) / (6500 - 1900)))
    return min(0.72, (intensity / 100.0) * warmth * 0.72)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def fit(draw, text, max_width, path, start, minimum=18):
    size = start
    while size > minimum:
        f = ImageFont.truetype(str(path), size)
        if draw.textlength(text, font=f) <= max_width:
            return f
        size -= 2
    return ImageFont.truetype(str(path), minimum)


def background() -> Image.Image:
    img = Image.new("RGB", (W, H), NAVY)
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        d.line(
            [(0, y), (W, y)],
            fill=(
                int(18 + (7 - 18) * t),
                int(28 + (11 - 28) * t),
                int(48 + (20 - 48) * t),
            ),
        )
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([W * 0.1, -H * 0.3, W * 0.9, H * 0.45], fill=(52, 34, 14))
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    return Image.blend(img, Image.blend(img, glow, 0.5), 0.5)


def caption(img: Image.Image, text: str, *, y: int = 96) -> None:
    d = ImageDraw.Draw(img)
    f = fit(d, text, W - 160, FONT_DIR / "DejaVuSans-Bold.ttf", 50)
    box = d.textbbox((0, 0), text, font=f)
    tw = box[2] - box[0]
    th = box[3] - box[1]
    d.rounded_rectangle(
        [(W - tw) / 2 - 34, y - 18, (W + tw) / 2 + 34, y + th + 30],
        radius=22,
        fill=(10, 16, 32),
        outline=(42, 58, 85),
    )
    d.text(((W - tw) / 2, y), text, font=f, fill=TEXT)


def phone_frame(screen: Image.Image, scale: float = 0.76) -> Image.Image:
    canvas = background()
    target_h = int(H * scale)
    target_w = int(screen.width * target_h / screen.height)
    shot = screen.resize((target_w, target_h), Image.LANCZOS).convert("RGB")
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, shot.width - 1, shot.height - 1], radius=48, fill=255
    )
    sh = Image.new("L", canvas.size, 0)
    sh.paste(mask, ((W - target_w) // 2, (H - target_h) // 2))
    sh = sh.filter(ImageFilter.GaussianBlur(40))
    canvas = Image.composite(
        Image.new("RGB", canvas.size, (0, 0, 0)), canvas, sh.point(lambda v: int(v * 0.55))
    )
    canvas.paste(shot, ((W - target_w) // 2, (H - target_h) // 2), mask)
    return canvas


def mock_browser() -> Image.Image:
    img = Image.new("RGB", (W, H), (250, 250, 252))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, 150], fill=(238, 240, 245))
    d.rounded_rectangle([40, 60, W - 40, 130], radius=35, fill=(255, 255, 255))
    d.text((70, 82), "example.com/article", font=font("DejaVuSans.ttf", 34), fill=(120, 128, 140))
    y = 210
    d.text((60, y), "Evening reading", font=font("DejaVuSans-Bold.ttf", 58), fill=(24, 28, 36))
    y += 90
    for i in range(9):
        width = W - 120 if i % 4 else W - 320
        d.rounded_rectangle([60, y, 60 + width, y + 26], radius=13, fill=(208, 212, 220))
        y += 52
    d.rounded_rectangle([60, y + 20, W - 60, y + 300], radius=24, fill=(226, 230, 238))
    d.text((90, y + 60), "Chart placeholder", font=font("DejaVuSans.ttf", 32), fill=(150, 156, 168))
    return img


def with_tint(base: Image.Image, intensity: int, kelvin: int) -> Image.Image:
    r, g, b = kelvin_to_rgb(kelvin)
    overlay = Image.new("RGB", base.size, (r, g, b))
    return Image.blend(base, overlay, tint_alpha(intensity, kelvin))


def title_card() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    mark = Image.open(ROOT / "deploy/playstore/graphics/app-icon-512.png").convert("RGBA")
    mark = mark.resize((280, 280), Image.LANCZOS)
    img.paste(mark, ((W - 280) // 2, 620), mark)
    f = fit(d, "LumaShield", W - 200, FONT_DIR / "DejaVuSans-Bold.ttf", 110)
    d.text(((W - d.textlength("LumaShield", font=f)) / 2, 940), "LumaShield", font=f, fill=TEXT)
    f2 = fit(d, "Blue light filter demo", W - 260, FONT_DIR / "DejaVuSans.ttf", 54)
    d.text(
        ((W - d.textlength("Blue light filter demo", font=f2)) / 2, 1075),
        "Blue light filter demo",
        font=f2,
        fill=AMBER,
    )
    return img


def end_card() -> Image.Image:
    img = background()
    d = ImageDraw.Draw(img)
    for text, y in [("No account", 760), ("No ads", 860), ("No internet permission", 960)]:
        f = fit(d, text, W - 240, FONT_DIR / "DejaVuSans-Bold.ttf", 58)
        d.text(((W - d.textlength(text, font=f)) / 2, y), text, font=f, fill=TEXT)
    f = fit(d, "LumaShield", W - 300, FONT_DIR / "DejaVuSans-Bold.ttf", 72)
    d.text(((W - d.textlength("LumaShield", font=f)) / 2, 1130), "LumaShield", font=f, fill=AMBER)
    return img


def build_scenes() -> list[tuple[Image.Image, float]]:
    scenes: list[tuple[Image.Image, float]] = []
    scenes.append((title_card(), 2.5))

    dash = phone_frame(Image.open(SHOTS / "01_dashboard.png").convert("RGB"))
    caption(dash, "Protection on · 100% reduction")
    scenes.append((dash, 3.5))

    browser = mock_browser()
    plain = phone_frame(browser)
    caption(plain, "Another app, no filter")
    scenes.append((plain, 2.5))

    tinted = phone_frame(with_tint(browser, 90, 2200))
    caption(tinted, "Overlay applied above other apps")
    scenes.append((tinted, 3.5))

    paused = phone_frame(browser)
    caption(paused, "User taps Pause")
    scenes.append((paused, 2.5))

    resumed = phone_frame(with_tint(browser, 90, 2200))
    caption(resumed, "Resume brings it straight back")
    scenes.append((resumed, 2.5))

    settings = phone_frame(Image.open(SHOTS / "02_filter_settings.png").convert("RGB"))
    caption(settings, "Adjustable from the app")
    scenes.append((settings, 3.0))

    scenes.append((end_card(), 2.5))
    return scenes


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    scenes = build_scenes()

    target = OUT / "fgs-demo.mp4"
    # Frames are piped straight into the encoder at a fixed rate. The concat
    # demuxer with per-image durations produced blended frames around scene
    # changes, so it is avoided entirely.
    encoder = subprocess.Popen(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-f", "rawvideo", "-pix_fmt", "rgb24",
            "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
            "-c:v", "libx264", "-preset", "medium", "-crf", "20",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            str(target),
        ],
        stdin=subprocess.PIPE,
    )
    assert encoder.stdin is not None
    for image, seconds in scenes:
        frame = image.convert("RGB").tobytes()
        for _ in range(int(round(seconds * FPS))):
            encoder.stdin.write(frame)
    encoder.stdin.close()
    if encoder.wait() != 0:
        raise SystemExit("ffmpeg failed")

    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration,size",
         "-of", "default=nw=1", str(target)],
        capture_output=True,
        text=True,
        check=True,
    )
    print(probe.stdout.strip())
    print("video:", target.relative_to(ROOT))


if __name__ == "__main__":
    main()
