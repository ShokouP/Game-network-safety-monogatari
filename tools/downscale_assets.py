#!/usr/bin/env python3
## 缩放 + 量化生成的像素头像，让 1024 -> 32x32 像素风
from pathlib import Path
from PIL import Image

def downscale(src: Path, dst: Path, size: tuple, quantize: bool = True):
    img = Image.open(src).convert("RGB")  # 先转 RGB 避免 RGBA quantize 限制
    img = img.resize((size[0]*8, size[1]*8), Image.LANCZOS)
    if quantize:
        img = img.quantize(colors=32, method=Image.MEDIANCUT).convert("RGB")
    img = img.resize(size, Image.NEAREST)
    img.save(dst, "PNG", optimize=True)

def main():
    root = Path("C:/CyberCairo/assets")
    # 员工头像：1024 -> 64x64（保留可读性）
    for f in (root/"sprites"/"employees").glob("*.png"):
        out = f.with_name(f.stem + "_64.png")
        downscale(f, out, (64, 64))
        print(f"  {out.name}")
    # 设施：1024 -> 96x96
    for f in (root/"sprites"/"facilities").glob("*.png"):
        out = f.with_name(f.stem + "_96.png")
        downscale(f, out, (96, 96))
        print(f"  {out.name}")
    # 事件：1024 -> 64x64
    for f in (root/"incidents").glob("*.png"):
        out = f.with_name(f.stem + "_64.png")
        downscale(f, out, (64, 64))
        print(f"  {out.name}")
    # tiles：1024 -> 32x32 平铺
    for f in (root/"tiles").glob("*.png"):
        if f.stem == "desk":
            out = f.with_name(f.stem + "_32x64.png")
            downscale(f, out, (32, 64))
        else:
            out = f.with_name(f.stem + "_32.png")
            downscale(f, out, (32, 32))
        print(f"  {out.name}")

if __name__ == "__main__":
    main()
