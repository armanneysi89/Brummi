"""Stellt die Roh-Assets frei (rembg), schneidet sie zu und legt sie skaliert unter assets/ ab."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from rembg import new_session, remove

TOOLS = Path(__file__).parent
RAW = TOOLS / "raw"
ASSETS = TOOLS.parent / "assets"

# name -> (Zielordner, Zielhöhe in px, freistellen)
ITEMS = {
    "bear_idle": ("brummi", None, True),
    "bear_run1": ("brummi", None, True),
    "bear_run2": ("brummi", None, True),
    "bear_run3": ("brummi", None, True),
    "bear_jump": ("brummi", None, True),
    "bear_fall": ("brummi", None, True),
    "bear_punch": ("brummi", None, True),
    "bear_dash": ("brummi", None, True),
    "bear_hurt": ("brummi", None, True),
    "bear_victory": ("brummi", None, True),
    "bear_special": ("brummi", None, True),
    "bear_shoot": ("brummi", None, True),
    "bear_portrait": ("ui", 256, True),
    "graupelz_idle": ("monster", 480, True),
    "graupelz_stunned": ("monster", 480, True),
    "graupelz_hurt": ("monster", 480, True),
    "graupelz_flee": ("monster", 480, True),
    "pip_caged": ("characters", 360, True),
    "pip_happy": ("characters", 220, True),
    "eule": ("characters", 400, True),
    "lollipop": ("items", 160, True),
    "star": ("items", 160, True),
    "intro1": ("story", None, False),
    "intro2": ("story", None, False),
    "intro3": ("story", None, False),
    "intro4": ("story", None, False),
    "intro5": ("story", None, False),
    "intro6": ("story", None, False),
    "outro1": ("story", None, False),
    "outro2": ("story", None, False),
    "sheep_ref": ("enemy", None, True),
    "sheep_walk": ("enemy", None, True),
    "sheep_hit": ("enemy", None, True),
    "coin": ("items", 128, True),
    "heart": ("ui", 96, True),
    "crystal": ("objects", 320, True),
    "mushroom": ("objects", 220, True),
    "glowflower": ("objects", 320, True),
    "crate": ("objects", 200, True),
    "sign": ("objects", 300, True),
    "portal": ("objects", 640, True),
    "bridge": ("terrain", 300, True),
    "ground1": ("terrain", 900, True),
    "ground2": ("terrain", 900, True),
    "island": ("terrain", 500, True),
    "bush": ("objects", 300, True),
    "tree": ("objects", 1100, True),
    "bg_island1": ("background", 600, True),
    "bg_island2": ("background", 600, True),
    "bg_sky": ("background", None, False),
    # Level 2
    "anaja": ("characters", 360, True),
    "anaja_sad": ("characters", 360, True),
    "anaja_run": ("characters", 360, True),
    "anaja_happy": ("characters", 360, True),
    "anaja_portrait": ("ui", 256, True),
    "mama_wave": ("characters", 480, True),
    "graupelz_disguise": ("monster", 480, True),
    "crab_ref": ("enemy", None, True),
    "crab_walk": ("enemy", None, True),
    "crab_happy": ("enemy", None, True),
    "gull_ref": ("enemy", 240, True),
    "gull_fly": ("enemy", 240, True),
    "gull_happy": ("enemy", 240, True),
    "heart_shot": ("items", 128, True),
    "lantern": ("objects", 600, True),
    "barrel": ("objects", 200, True),
    "palm": ("objects", 1100, True),
    "shells": ("objects", 200, True),
    "anchor": ("objects", 260, True),
    "lighthouse": ("objects", 1000, True),
    "pier": ("terrain", 300, True),
    "sand1": ("terrain", 900, True),
    "sand2": ("terrain", 900, True),
    "raft": ("terrain", 500, True),
    "bg_boat": ("background", 600, True),
    "bg_rock": ("background", 600, True),
    "bg_sky2": ("background", None, False),
    **{f"l2_{k}": ("story", None, False) for k in ("intro1", "intro2", "intro3", "intro4", "intro5", "intro6", "outro1", "outro2")},
    # Hauptmenü
    "menu_bg": ("story", None, False),
    "menu_card1": ("story", None, False),
    "menu_card2": ("story", None, False),
}

# Einige Assets stammen direkt aus den Referenz-Kandidaten
SOURCES = {"graupelz_idle": RAW / "cand" / "graupelz_101.png", "eule": RAW / "cand" / "eule_101.png", "anaja": RAW / "anaja_ref.png"}

# Charakter-Frames werden alle mit demselben Faktor skaliert, damit die Größe konsistent bleibt.
CHAR_SCALE = {"bear": 0.24, "sheep": 0.17, "crab": 0.17}


def crop_alpha(img: Image.Image, pad: int = 4) -> Image.Image:
    a = np.array(img.getchannel("A"))
    ys, xs = np.where(a > 24)
    box = (max(xs.min() - pad, 0), max(ys.min() - pad, 0), min(xs.max() + pad + 1, img.width), min(ys.max() + pad + 1, img.height))
    return img.crop(box)


def clean_alpha(img: Image.Image) -> Image.Image:
    arr = np.array(img)
    a = arr[..., 3].astype(np.float32)
    arr[..., 3] = np.clip((a - 20.0) * 255.0 / 215.0, 0, 255).astype(np.uint8)
    return Image.fromarray(arr)


def main() -> None:
    only = set(sys.argv[1:])
    session = new_session("isnet-general-use")
    for name, (folder, height, cut) in ITEMS.items():
        src = SOURCES.get(name, RAW / f"{name}.png")
        if not src.exists() or (only and name not in only):
            continue
        img = Image.open(src).convert("RGBA")
        if cut:
            img = crop_alpha(clean_alpha(remove(img, session=session)))
        prefix = name.split("_")[0]
        if prefix in CHAR_SCALE and name != "bear_portrait":
            f = CHAR_SCALE[prefix]
            img = img.resize((round(img.width * f), round(img.height * f)), Image.LANCZOS)
        elif height:
            img = img.resize((round(img.width * height / img.height), height), Image.LANCZOS)
        out = ASSETS / folder / f"{name}.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out)
        print(name, img.size, flush=True)


if __name__ == "__main__":
    main()
