#!/usr/bin/env python3
## 生成 3 张楼层地图（2.5D 像素办公室）
import os, sys, json, base64, requests, time
from pathlib import Path

def _load_key() -> str:
    key = os.environ.get("VOLC_API_KEY") or os.environ.get("ARK_API_KEY")
    if key:
        return key
    env_file = Path.home() / ".config" / "cybercairo" / ".env.volc"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            if line.startswith("VOLC_API_KEY="):
                return line.split("=", 1)[1].strip()
    raise RuntimeError("no api key")

API_KEY = _load_key()
BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
MODEL = "doubao-seedream-5-0-pro-260628"

def gen(prompt: str, out_path: Path, size: str = "1024x1024") -> bool:
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
        if not b64:
            url = data["data"][0].get("url")
            if url:
                img = requests.get(url, timeout=60).content
                out_path.write_bytes(img)
                print(f"    [ok/url] {len(img)} bytes")
                return True
            print(f"    [fail] no b64/url")
            return False
        img = base64.b64decode(b64)
        out_path.write_bytes(img)
        print(f"    [ok] {len(img)} bytes")
        return True
    except requests.exceptions.RequestException as e:
        print(f"    [error] {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"    body: {e.response.text[:500]}")
        return False

def main():
    root = Path("C:/CyberCairo/assets/tiles/maps")
    root.mkdir(parents=True, exist_ok=True)

    common = "Kairosoft style, 16-bit pixel art, 2.5D isometric top-down 45-degree view, retro simulation game map, cute chibi proportions, vibrant colors, sharp pixel edges, clean composition, no text, no UI"

    tasks = [
        (
            "Pixel art 2.5D office floor plan, isometric top-down 45-degree view, 12 workstation cubicles arranged in 4 columns x 3 rows, each workstation has a desk with CRT monitor keyboard and office chair, beige carpet floor with subtle grid, large windows along the top wall letting in warm sunlight rays, potted plants in corners, water cooler, Kairosoft style, 16-bit, retro simulation game, cute, vibrant colors, no people, no text, no UI",
            root / "map_f1_office.jpg",
        ),
        (
            "Pixel art 2.5D security operations center SOC, isometric top-down 45-degree view, large video wall with multiple green radar screens and world map, rows of server racks with blinking lights, training classroom corner with blackboard and desks and chairs, break lounge corner with coffee machine and sofa and vending machine, dark blue metallic raised floor with cable channels, Kairosoft style, 16-bit, retro simulation game, no people, no text, no UI",
            root / "map_f2_operations.jpg",
        ),
        (
            "Pixel art 2.5D research laboratory floor, isometric top-down 45-degree view, lab benches with test tubes beakers microscopes and computers glowing blue liquids, forensics analysis room corner with giant magnifying glass and fingerprint evidence board, public relations office corner with microphone TV camera and interview desk, purple anti-static floor with subtle hex pattern, Kairosoft style, 16-bit, retro simulation game, no people, no text, no UI",
            root / "map_f3_research.jpg",
        ),
    ]

    ok, fail = 0, 0
    for prompt, out in tasks:
        if gen(prompt, out, "1024x1024"):
            ok += 1
        else:
            fail += 1
        time.sleep(0.8)
    print(f"\nDone. ok={ok} fail={fail}")

if __name__ == "__main__":
    main()
