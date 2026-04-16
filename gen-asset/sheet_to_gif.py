from pathlib import Path
from PIL import Image
import numpy as np
INPUT_DIR = Path("./raw_sheets")
OUTPUT_DIR = Path("./assets/game/balls/gif")

STATE_CFG = {
    "idle_loop": {"frames": 16, "duration": 70},
    "selected_path_loop": {"frames": 14, "duration": 65},
    "destroying_out": {"frames": 15, "duration": 52},
}

VALUES = [128, 256, 512, 1024, 2048]


def rgba_to_transparent_p(rgba: Image.Image, transparent_index: int = 255) -> Image.Image:
    p = rgba.convert("P", palette=Image.ADAPTIVE,
                     colors=255, dither=Image.FLOYDSTEINBERG)
    a = np.array(rgba.getchannel("A"), dtype=np.uint8)
    pa = np.array(p, dtype=np.uint8)
    pa[a == 0] = transparent_index
    out = Image.fromarray(pa, mode="P")
    out.putpalette(p.getpalette())
    pal = out.getpalette()
    if len(pal) < 768:
        pal += [0] * (768 - len(pal))
    pal[transparent_index * 3: transparent_index * 3 + 3] = [0, 0, 0]
    out.putpalette(pal)
    out.info["transparency"] = transparent_index
    return out


def split_sheet(sheet_path: Path):
    im = Image.open(sheet_path).convert("RGBA")
    w, h = im.size
    cw, ch = w // 4, h // 4
    frames = []
    for i in range(16):
        c = i % 4
        r = i // 4
        frame = im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
        frames.append(frame)
    return frames


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for v in VALUES:
        for state, cfg in STATE_CFG.items():
            sheet = INPUT_DIR / f"ball_{v}_{state}_sheet.png"
            if not sheet.exists():
                print(f"Missing: {sheet}")
                continue

            frames = split_sheet(sheet)[: cfg["frames"]]
            pframes = [rgba_to_transparent_p(f, 255) for f in frames]

            out = OUTPUT_DIR / f"ball_{v}_{state}.gif"
            pframes[0].save(
                out,
                save_all=True,
                append_images=pframes[1:],
                duration=cfg["duration"],
                loop=0,
                disposal=2,
                transparency=255,
                optimize=False,
            )
            print("Wrote", out)


if __name__ == "__main__":
    main()
