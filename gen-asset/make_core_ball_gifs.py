from pathlib import Path
from PIL import Image
import numpy as np

INPUT_DIR = Path("./raw_sheets")  # chứa 3 PNG sheet
OUTPUT_DIR = Path("./assets/game/balls/gif")

STATE_CONFIG = {
    "idle_loop": {
        "sheet": "ball_core_idle_loop_sheet.png",
        "out": "ball_core_idle_loop.gif",
        "frames": 16,
        "duration": 70,
    },
    "selected_path_loop": {
        "sheet": "ball_core_selected_path_loop_sheet.png",
        "out": "ball_core_selected_path_loop.gif",
        "frames": 14,  # match timeline cũ
        "duration": 65,
    },
    "destroying_out": {
        "sheet": "ball_core_destroying_out_sheet.png",
        "out": "ball_core_destroying_out.gif",
        "frames": 15,  # match timeline cũ
        "duration": 52,
    },
}

def rgba_to_transparent_p(rgba: Image.Image, transparent_index: int = 255) -> Image.Image:
    p = rgba.convert("P", palette=Image.ADAPTIVE, colors=255, dither=Image.FLOYDSTEINBERG)
    alpha = np.array(rgba.getchannel("A"), dtype=np.uint8)
    p_arr = np.array(p, dtype=np.uint8)
    p_arr[alpha == 0] = transparent_index

    out = Image.fromarray(p_arr, mode="P")
    out.putpalette(p.getpalette())

    pal = out.getpalette()
    if len(pal) < 768:
        pal += [0] * (768 - len(pal))
    pal[transparent_index * 3 : transparent_index * 3 + 3] = [0, 0, 0]
    out.putpalette(pal)
    out.info["transparency"] = transparent_index
    return out

def split_4x4(sheet: Image.Image):
    w, h = sheet.size
    assert w == 1024 and h == 1024, f"Sheet phải 1024x1024, nhận {w}x{h}"
    cell_w, cell_h = w // 4, h // 4
    frames = []
    for i in range(16):
        c = i % 4
        r = i // 4
        frame = sheet.crop((c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h))
        frames.append(frame.convert("RGBA"))
    return frames

def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for state, cfg in STATE_CONFIG.items():
        sheet_path = INPUT_DIR / cfg["sheet"]
        if not sheet_path.exists():
            print(f"[MISS] {sheet_path}")
            continue

        sheet = Image.open(sheet_path).convert("RGBA")
        frames = split_4x4(sheet)[: cfg["frames"]]
        pframes = [rgba_to_transparent_p(f) for f in frames]

        out_path = OUTPUT_DIR / cfg["out"]
        pframes[0].save(
            out_path,
            save_all=True,
            append_images=pframes[1:],
            duration=cfg["duration"],
            loop=0,
            disposal=2,
            transparency=255,
            optimize=False,
        )
        print(f"[OK] {state} -> {out_path}")

if __name__ == "__main__":
    main()
