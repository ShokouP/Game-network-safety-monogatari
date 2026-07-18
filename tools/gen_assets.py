#!/usr/bin/env python3
## 调用火山方舟 seedream 批量生图
import os, sys, json, base64, requests, time
from pathlib import Path

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

def gen(prompt: str, out_path: Path, size: str = "1024x1024") -> bool:
    if out_path.exists():
        print(f"  [skip] {out_path.name}")
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
        r = requests.post(f"{BASE_URL}/images/generations", headers=headers, json=payload, timeout=120)
        r.raise_for_status()
        data = r.json()
        b64 = data["data"][0].get("b64_json")
        if not b64:
            # fallback to URL
            url = data["data"][0].get("url")
            if url:
                img = requests.get(url, timeout=60).content
                out_path.write_bytes(img)
                print(f"    [ok/url] {len(img)} bytes")
                return True
            print(f"    [fail] no b64/url in response: {list(data.get('data',[{}])[0].keys())}")
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
    root = Path("C:/CyberCairo/assets")
    tasks = []

    # 6 种员工专长头像（32x32 风格像素，让模型生成 1024 后续可缩放）
    specialties = [
        ("general",    "Pixel art portrait, 32x32 retro game style, security analyst avatar, neutral gray hoodie, headphones, friendly face, top-down 2D game sprite, transparent-like solid dark background, Kairosoft style, 16-bit, chibi proportions, single character centered"),
        ("phishing",   "Pixel art portrait, 32x32 retro game style, email security expert avatar, orange hoodie, holding magnifying glass inspecting mail icon, 16-bit chibi, dark solid background, Kairosoft style, single character centered"),
        ("malware",    "Pixel art portrait, 32x32 retro game style, malware reverse engineer avatar, red-black hoodie, virus skull icon on chest, glasses, 16-bit chibi, dark solid background, Kairosoft style, single character centered"),
        ("network",    "Pixel art portrait, 32x32 retro game style, network security engineer avatar, blue hoodie, ethernet cable and router icon, 16-bit chibi, dark solid background, Kairosoft style, single character centered"),
        ("forensics",  "Pixel art portrait, 32x32 retro game style, digital forensics expert avatar, purple hoodie, magnifier and fingerprint icon, 16-bit chibi, dark solid background, Kairosoft style, single character centered"),
        ("compliance", "Pixel art portrait, 32x32 retro game style, compliance auditor avatar, green vest, holding clipboard with checkmark, 16-bit chibi, dark solid background, Kairosoft style, single character centered"),
    ]
    for sid, prompt in specialties:
        tasks.append((prompt, root / "sprites" / "employees" / f"{sid}.png", "1024x1024"))

    # 6 种部门设施图标（64x64 风格）
    facilities = [
        ("training_room", "Pixel art 64x64 retro game icon, training classroom with books and chalkboard, Kairosoft style, 16-bit, warm lighting, top-down isometric view, single object on dark background"),
        ("soc",           "Pixel art 64x64 retro game icon, security operations center, multi-monitor wall with green radar screens, Kairosoft style, 16-bit, dark background"),
        ("lab",           "Pixel art 64x64 retro game icon, research laboratory, beakers and computers, glowing blue liquids, Kairosoft style, 16-bit, dark background"),
        ("forensics",     "Pixel art 64x64 retro game icon, forensics analysis room, magnifying glass over fingerprint on screen, Kairosoft style, 16-bit, dark background"),
        ("pr_office",     "Pixel art 64x64 retro game icon, public relations office, megaphone and microphone, Kairosoft style, 16-bit, dark background"),
        ("lounge",        "Pixel art 64x64 retro game icon, employee lounge, coffee machine sofa plants, Kairosoft style, 16-bit, cozy warm, dark background"),
    ]
    for fid, prompt in facilities:
        tasks.append((prompt, root / "sprites" / "facilities" / f"{fid}.png", "1024x1024"))

    # 地板 tiles（不同楼层风格）
    tiles = [
        ("floor_f1", "Seamless tileable pixel art floor texture, 32x32 game tile, office beige carpet with subtle grid, Kairosoft style, top-down 2D, flat, 16-bit"),
        ("floor_f2", "Seamless tileable pixel art floor texture, 32x32 game tile, server room raised floor, dark blue-green metal tiles with tiny vent holes, 16-bit"),
        ("floor_f3", "Seamless tileable pixel art floor texture, 32x32 game tile, laboratory purple-gray anti-static floor with subtle hex pattern, 16-bit"),
        ("wall",     "Seamless tileable pixel art office wall texture, 32x32 game tile, beige with white baseboard, 16-bit Kairosoft style"),
        ("desk",     "Pixel art 32x64 office desk with monitor keyboard, Kairosoft style, top-down view, 16-bit, dark background"),
    ]
    for tid, prompt in tiles:
        tasks.append((prompt, root / "tiles" / f"{tid}.png", "1024x1024"))

    # 10 种事件插画（用于事件卡）
    incidents = [
        ("phishing",     "Pixel art 64x64 icon, phishing email attack, envelope with fish hook, dark red warning background, 16-bit Kairosoft style"),
        ("malware",      "Pixel art 64x64 icon, malware infection, computer screen with skull virus, dark red warning background, 16-bit Kairosoft style"),
        ("ransomware",   "Pixel art 64x64 icon, ransomware attack, locked folder with chains and padlock, red warning background, 16-bit Kairosoft style"),
        ("ddos",         "Pixel art 64x64 icon, DDoS attack, tsunami wave of arrows hitting server, orange warning background, 16-bit Kairosoft style"),
        ("insider",      "Pixel art 64x64 icon, insider threat, silhouette figure stealing USB drive, dark purple warning background, 16-bit Kairosoft style"),
        ("supply_chain", "Pixel art 64x64 icon, supply chain attack, broken chain link with virus icon, dark red background, 16-bit Kairosoft style"),
        ("social_eng",   "Pixel art 64x64 icon, social engineering, two faced mask with phone, orange warning background, 16-bit Kairosoft style"),
        ("zero_day",     "Pixel art 64x64 icon, zero-day exploit, glowing zero with crack and warning symbol, deep red background, 16-bit Kairosoft style"),
        ("web_attack",   "Pixel art 64x64 icon, SQL injection web attack, browser window with syringe and code, red warning background, 16-bit Kairosoft style"),
        ("apt",          "Pixel art 64x64 icon, APT advanced persistent threat, ninja shadow figure in network cables, dark purple background, 16-bit Kairosoft style"),
    ]
    for iid, prompt in incidents:
        tasks.append((prompt, root / "incidents" / f"{iid}.png", "1024x1024"))

    print(f"Total tasks: {len(tasks)}")
    ok = 0
    fail = 0
    for prompt, out, size in tasks:
        if gen(prompt, out, size):
            ok += 1
        else:
            fail += 1
        time.sleep(0.5)
    print(f"\nDone. ok={ok} fail={fail}")

if __name__ == "__main__":
    main()
