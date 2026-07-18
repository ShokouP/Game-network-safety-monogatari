#!/usr/bin/env python3
## 把生成的像素头像背景转透明
## 思路：取四角像素的中位数作为背景色，然后从边缘向内 flood fill，
## 把与背景色欧氏距离 < threshold 的连通像素转透明。
from pathlib import Path
from PIL import Image
from collections import deque
import math

def get_bg_color(img) -> tuple:
    w, h = img.size
    samples = []
    for x, y in [(0,0), (w-1,0), (0,h-1), (w-1,h-1),
                 (w//2,0), (w//2,h-1), (0,h//2), (w-1,h//2)]:
        p = img.getpixel((x, y))[:3]
        samples.append(p)
    # 中位数
    r = sorted(s[0] for s in samples)[len(samples)//2]
    g = sorted(s[1] for s in samples)[len(samples)//2]
    b = sorted(s[2] for s in samples)[len(samples)//2]
    return (r, g, b)

def color_dist(a: tuple, b: tuple) -> float:
    return math.sqrt(sum((x-y)**2 for x, y in zip(a, b)))

def remove_background(src: Path, dst: Path, threshold: float = 35.0):
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    pixels = img.load()
    bg = get_bg_color(img)
    visited = [[False]*w for _ in range(h)]
    queue = deque()
    # 4 角 + 4 边中点
    seeds = [(0,0), (w-1,0), (0,h-1), (w-1,h-1),
             (w//2,0), (w//2,h-1), (0,h//2), (w-1,h//2)]
    for sx, sy in seeds:
        if color_dist(pixels[sx, sy][:3], bg) < threshold and not visited[sy][sx]:
            queue.append((sx, sy))
            visited[sy][sx] = True
    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        for dx, dy in [(1,0), (-1,0), (0,1), (0,-1)]:
            nx, ny = x+dx, y+dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx]:
                if color_dist(pixels[nx, ny][:3], bg) < threshold:
                    visited[ny][nx] = True
                    queue.append((nx, ny))
    img.save(dst, "PNG", optimize=True)
    print(f"  {dst.name}  bg={bg}")

def main():
    root = Path("C:/CyberCairo/assets/sprites/employees")
    for f in root.glob("*_64.png"):
        if "_transparent" in f.stem:
            continue
        out = f.with_name(f.stem + "_transparent.png")
        remove_background(f, out)

if __name__ == "__main__":
    main()
