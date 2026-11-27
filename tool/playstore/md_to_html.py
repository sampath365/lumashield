"""Converts the store documents to standalone HTML pages.

    python3 tool/playstore/md_to_html.py

Writes docs/privacy.html (served by GitHub Pages) and a copy inside the deploy
pack. The page is a single file with no external assets, so it can be uploaded
to any host as is.
"""

from __future__ import annotations

import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "deploy/playstore/privacy-policy.md"
TARGETS = [
    ROOT / "docs/privacy.html",
    ROOT / "deploy/playstore/privacy-policy.html",
]

STYLE = """
  :root { color-scheme: dark; }
  body {
    margin: 0 auto; max-width: 46rem; padding: 2.5rem 1.25rem 5rem;
    background: #0b1020; color: #dfe6f3;
    font: 16px/1.65 -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  }
  h1 { font-size: 2rem; line-height: 1.2; margin: 0 0 1.5rem; color: #f4f7ff; }
  h2 { font-size: 1.15rem; margin: 2rem 0 .5rem; color: #f0a44a; }
  p, li { color: #b9c4d6; }
  ul { padding-left: 1.2rem; }
  li { margin-bottom: .35rem; }
  a { color: #f0a44a; }
  strong { color: #f2f6ff; }
  code { background: #16203a; padding: .1rem .35rem; border-radius: 6px; font-size: .92em; }
  .badge {
    display: inline-block; padding: .3rem .7rem; border-radius: 999px;
    background: #16203a; color: #8fa3c2; font-size: .8rem; margin-bottom: 1.5rem;
  }
  footer { margin-top: 3rem; border-top: 1px solid #1e2a40; padding-top: 1rem; color: #7f8ea8; font-size: .85rem; }
"""


def inline(text: str) -> str:
    text = html.escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    text = re.sub(r"\[(.+?)\]\((http[^)]+)\)", r'<a href="\2">\1</a>', text)
    return text


def convert(markdown: str) -> list[str]:
    out: list[str] = []
    paragraph: list[str] = []
    in_list = False

    def flush_paragraph() -> None:
        if paragraph:
            out.append(f"<p>{inline(' '.join(paragraph))}</p>")
            paragraph.clear()

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for raw in markdown.splitlines():
        line = raw.strip()
        if not line:
            flush_paragraph()
            close_list()
            continue
        if line.startswith("# "):
            flush_paragraph()
            close_list()
            out.append(f"<h1>{inline(line[2:])}</h1>")
        elif line.startswith("## "):
            flush_paragraph()
            close_list()
            out.append(f"<h2>{inline(line[3:])}</h2>")
        elif line.startswith("- ") or line.startswith("* "):
            flush_paragraph()
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(line[2:])}</li>")
        elif in_list:
            out[-1] = out[-1][:-5] + " " + inline(line) + "</li>"
        else:
            paragraph.append(line)

    flush_paragraph()
    close_list()
    return out


def build(markdown: str) -> str:
    body = "\n".join(convert(markdown))
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>LumaShield privacy policy</title>
<meta name="description" content="Privacy policy for LumaShield, the blue light filter and eye care app.">
<style>{STYLE}</style>
</head>
<body>
<span class="badge">LumaShield &middot; com.lumashield.app</span>
{body}
<footer>LumaShield is not a medical device. Questions:
<a href="mailto:msg4sampath@gmail.com">msg4sampath@gmail.com</a></footer>
</body>
</html>
"""


def main() -> None:
    page = build(SOURCE.read_text())
    for target in TARGETS:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(page)
        print("wrote", target.relative_to(ROOT), f"({len(page)} bytes)")


if __name__ == "__main__":
    main()
