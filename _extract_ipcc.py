"""Extract text from specified pages of an IPCC PDF and print to stdout."""
import sys, pypdf, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
path, start, end = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
r = pypdf.PdfReader(path)
for i in range(start - 1, min(end, len(r.pages))):
    print(f"=== page {i+1} ===")
    print(r.pages[i].extract_text())
    print()
