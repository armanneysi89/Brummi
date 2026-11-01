"""Assets für das Hauptmenü: Hintergrund und Level-Karten im Story-Stil."""
import sys
from pathlib import Path

from comfy import generate

RAW = Path(__file__).parent / "raw"
BRUMMI = RAW / "brummi_ref2.png"
PIP = RAW / "cand" / "pip_101.png"
ANAJA = RAW / "anaja_ref.png"

SPRITE = ("Centered on a plain flat light grey background, nothing else in the image. Same flat 2D cartoon style with cel shading "
          "and bold dark brown outlines.")
SCENE = ("Wide cinematic storybook illustration for a children's game, lush painterly fantasy art, vibrant warm colors, soft magical light, "
         "a magical valley with floating islands, waterfalls and a fairytale castle in the distance. No text, no letters. ")
CAST = "<CAST>"
DESC = {
    BRUMMI: "Brummi, a cute chibi caramel-brown teddy bear with big blue eyes and a red heart on his tummy patch",
    PIP: "Pip, a tiny white bunny with a blue scarf",
    ANAJA: "Anaja, a cute little fox girl with orange fur, a cream muzzle and a big fluffy tail",
}


def cast(refs):
    parts = [f"Image {i + 1} is {DESC[r]}." for i, r in enumerate(refs)]
    return (" ".join(parts) + f" Only these {len(refs)} characters appear in the scene, each exactly once, "
            "keep every character exactly as in its own reference image and do not mix their features. ")

JOBS = [
    ("menu_bg",
     "Wide cozy storybook illustration for a children's game main menu, lush painterly fantasy art, vibrant warm colors, soft magical "
     "twilight light. A magical valley at dusk: on the left a glowing lantern-lit meadow with a fairytale castle in the distance, on the "
     "right a golden sunset coast with a lighthouse and a small harbor. Floating islands and soft clouds in between, fireflies and warm "
     "lantern light. The middle of the image is calmer and darker, leaving room for a title. No text, no letters. ",
     1664, 928, 901, []),
    ("menu_card1",
     SCENE + CAST + "Brummi and Pip stand together on a sunny flower meadow, waving happily at the viewer, lanterns glowing softly around "
     "them, a fairytale castle in the distance. Warm inviting mood, like a level select card. ",
     1024, 640, 902, [BRUMMI, PIP]),
    ("menu_card2",
     "Wide cinematic storybook illustration for a children's game, lush painterly fantasy art, vibrant warm colors, soft magical light, "
     "a golden sunset coast with a glowing lighthouse, a small harbor with boats and lanterns. No text, no letters. " + CAST +
     "Brummi and Anaja stand together on a wooden pier, waving happily at the viewer, the lighthouse glowing behind them. Warm inviting "
     "mood, like a level select card. ",
     1024, 640, 903, [BRUMMI, ANAJA]),
]

if __name__ == "__main__":
    only = set(sys.argv[1:])
    for name, prompt, w, h, seed, refs in JOBS:
        out = RAW / f"{name}.png"
        if out.exists() or (only and name not in only):
            continue
        print("generating", name, flush=True)
        generate(prompt.replace(CAST, cast(refs)), out, w, h, seed, refs)
    print("done", flush=True)
