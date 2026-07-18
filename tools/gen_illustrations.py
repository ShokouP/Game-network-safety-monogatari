#!/usr/bin/env python3
## Generate 4 atmosphere illustrations for Security Dept Story via Volcano Ark seedream
import base64, os, time, requests
from pathlib import Path

# 从 .env.volc 或环境变量读 key（不要硬编码）
def _load_key() -> str:
    key = os.environ.get("VOLC_API_KEY") or os.environ.get("ARK_API_KEY")
    if key:
        return key
    env_file = Path(__file__).parent.parent / ".env.volc"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            if line.startswith("VOLC_API_KEY="):
                return line.split("=", 1)[1].strip()
    raise RuntimeError("未找到 API key：请设置 VOLC_API_KEY 环境变量或创建 .env.volc")

API_KEY = _load_key()
BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
MODEL = "doubao-seedream-5-0-pro-260628"
OUT = Path("C:/CyberCairo/assets/illustrations")
OUT.mkdir(parents=True, exist_ok=True)

def gen(prompt: str, out_path: Path, size: str = "1024x1024") -> bool:
    if out_path.exists() and out_path.stat().st_size > 10_000:
        print(f"  [skip] {out_path.name} ({out_path.stat().st_size} bytes)")
        return True
    print(f"  [gen] {out_path.name} ...", flush=True)
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "size": size,
        "response_format": "b64_json",
        "watermark": False,
    }
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
    try:
        r = requests.post(f"{BASE_URL}/images/generations", headers=headers, json=payload, timeout=180)
        r.raise_for_status()
        data = r.json()
        b64 = data["data"][0].get("b64_json")
        if b64:
            img = base64.b64decode(b64)
        else:
            url = data["data"][0].get("url")
            if not url:
                print(f"    [fail] no b64/url")
                return False
            img = requests.get(url, timeout=60).content
        out_path.write_bytes(img)
        print(f"    [ok] {len(img)} bytes")
        return True
    except Exception as e:
        print(f"    [error] {e}")
        if hasattr(e, "response") and e.response is not None:
            print(f"    body: {e.response.text[:500]}")
        return False

TASKS = [
    (
        "award_ceremony_bg.jpg",
        "Pixel art award ceremony stage background, 16-bit retro game style, golden stage curtains draped elegantly, spotlights beaming down from above, trophy pedestal in center, Kairosoft chibi game aesthetic, warm golden lighting, confetti in the air, portrait composition, vibrant colors, crisp pixels, no text",
    ),
    (
        "achievement_badge.jpg",
        "Pixel art golden hexagonal badge icon, 16-bit retro game style, trophy emblem in the center of the hexagon, shiny gold metallic gradient, dark navy background, Kairosoft game UI achievement medal, single centered object, crisp clean pixels, no text",
    ),
    (
        "game_logo.jpg",
        "Pixel art game logo illustration, 16-bit Kairosoft style, chibi pixel character wearing a yellow hard hat standing proudly on top of a large blue security shield, background with glowing network circuit lines and nodes, warm color palette orange and gold, cyber security theme, square composition, crisp retro pixels, no text",
    ),
    (
        "menu_bg.jpg",
        "Pixel art top-down isometric view of office at night, 16-bit Kairosoft style, security operations center room with rows of desks and computers, huge SOC monitoring wall screen glowing green, warm desk lamps, large window showing starry night sky, cozy atmosphere, landscape orientation composition, crisp retro game pixels, no text",
    ),
]

results = []
for fname, prompt in TASKS:
    ok = gen(prompt, OUT / fname)
    results.append((fname, ok))
    time.sleep(0.5)

print("\n=== Summary ===")
for fname, ok in results:
    p = OUT / fname
    size = p.stat().st_size if p.exists() else 0
    status = "OK" if (ok and size > 10_000) else "FAIL"
    print(f"  {status}: {fname} ({size} bytes)")
