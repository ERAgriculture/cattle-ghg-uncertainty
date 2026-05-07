"""One-off build script for the Andreas Wilkes review response.
Reuses parse_md and build_docx from _build_docs.py with corrected paths.
"""
from pathlib import Path
import sys

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))

from _build_docs import parse_md, build_docx

SRC = HERE / "docs" / "AW_review_response_v4.md"
DST = HERE / "AW_review_response_v4f.docx"

md = SRC.read_text(encoding="utf-8")
blocks = parse_md(md)
title = next((p for k, p in blocks if k == "h1"), "AW review response")

print(f"Building: {SRC.name}")
build_docx(blocks, DST, title)
print(f"Done -> {DST}")
