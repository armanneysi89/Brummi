"""Assets für Story, Graupelz, Pip, Oma Eule und Intro/Outro-Bilder (Brummi-Posen: siehe gen_level2.py)."""
import sys
from pathlib import Path

from comfy import generate

RAW = Path(__file__).parent / "raw"
CAND = RAW / "cand"
BRUMMI = RAW / "brummi_ref2.png"
GRAUPELZ = CAND / "graupelz_101.png"
PIP = CAND / "pip_101.png"
EULE = CAND / "eule_101.png"

SPRITE = ("Centered on a plain flat light grey background, nothing else in the image. Same flat 2D cartoon style with cel shading "
          "and bold dark brown outlines.")
MONSTER = ("Use image 1 as the exact character reference: the same big shaggy grey-violet fur monster Graupelz with two small curved horns, "
           "glowing yellow-green eyes and stubby legs. Full body. ")
SCENE = ("Wide cinematic storybook illustration for a children's game, lush painterly fantasy art, vibrant warm colors, soft magical light, "
         "a magical valley with floating islands, waterfalls and a fairytale castle in the distance. No text, no letters. ")
CAST = "<CAST>"
DESC = {
    BRUMMI: "Brummi, a cute chibi caramel-brown teddy bear with big blue eyes and a red heart on his tummy patch",
    PIP: "Pip, a tiny white bunny with a blue scarf",
    EULE: "Oma Eule, a kind old owl with round glasses and a purple shawl (she is an owl, NOT a monster)",
    GRAUPELZ: "Graupelz, a big shaggy grey-violet fur monster with small horns",
}


def cast(refs):
    parts = [f"Image {i + 1} is {DESC[r]}." for i, r in enumerate(refs)]
    return (" ".join(parts) + f" Only these {len(refs)} characters appear in the scene, each exactly once, "
            "keep every character exactly as in its own reference image and do not mix their features. ")

JOBS = [
    ("graupelz_stunned", MONSTER + "He is stunned and dizzy: covering his ears with both hands, eyes shown as swirls, the lollipop dropped, wobbling. " + SPRITE, 1024, 1024, 41, [GRAUPELZ]),
    ("graupelz_hurt", MONSTER + "He gets hit: recoiling backwards, eyes squeezed shut, saying ouch, fur puffed up. " + SPRITE, 1024, 1024, 42, [GRAUPELZ]),
    ("graupelz_flee", MONSTER + "He runs away in panic to the right, side view, arms flailing, scared face, dust cloud behind his feet. " + SPRITE, 1024, 1024, 43, [GRAUPELZ]),

    ("pip_caged", "Use image 1 as the exact character reference: the same tiny white bunny Pip with the blue scarf. He sits sadly inside a small wooden cage with a padlock, holding the bars, teary eyes. Full cage visible. " + SPRITE, 1024, 1024, 51, [PIP]),
    ("pip_happy", "Use image 1 as the exact character reference: the same tiny white bunny Pip with the blue scarf. Jumping with joy, arms raised, very happy smile. Full body. " + SPRITE, 1024, 1024, 52, [PIP]),

    ("lollipop", "A big colorful rainbow swirl lollipop candy on a white stick, isolated game item. " + SPRITE, 1024, 1024, 61, []),
    ("star", "A shiny golden star badge with a small red heart in the center and a soft glow, isolated game item icon. " + SPRITE, 1024, 1024, 62, []),

    ("intro1", SCENE + CAST + "Brummi and Pip play happily together on a sunny flower meadow, laughing, butterflies around them.", 1664, 928, 71, [BRUMMI, PIP]),
    ("intro2", SCENE + CAST + "Under a big old tree, Oma Eule talks kindly to Brummi and Pip who sit in the grass and listen carefully. Oma Eule raises one wing like a teacher.", 1664, 928, 72, [BRUMMI, PIP, EULE]),
    ("intro3", SCENE + CAST + "At the dark edge of the forest, Graupelz bends down to little Pip and offers him a big rainbow lollipop with a fake friendly grin. Pip looks curious. Slightly mysterious mood with purple shadows.", 1664, 928, 73, [PIP, GRAUPELZ]),
    ("intro4", SCENE + CAST + "View from behind: the small bunny Pip, holding a rainbow lollipop, walks away hand in hand with the big monster Graupelz along a darker, gloomy forest path with purple shadows. Nobody else is in the image.", 1664, 928, 274, [PIP, GRAUPELZ]),
    ("intro5", SCENE + CAST + "Brummi runs to Oma Eule and tells her everything, pointing excitedly towards the forest. Oma Eule listens with a serious and caring face.", 1664, 928, 75, [BRUMMI, EULE]),
    ("intro6", SCENE + CAST + "Oma Eule gives Brummi a glowing golden heart crystal. Brummi holds it bravely, looking towards the path into the valley, ready for an adventure.", 1664, 928, 76, [BRUMMI, EULE]),
    ("outro1", SCENE + CAST + "On the left Brummi stands bravely with both arms stretched forward like a stop sign, shouting. In the middle a single happy Pip jumps out of an open wooden cage. On the far right, the monster Graupelz runs away in panic, seen from the side, far in the background. Exactly one bunny in the whole image.", 1664, 928, 181, [BRUMMI, PIP, GRAUPELZ]),
    ("outro2", SCENE + CAST + "Warm golden sunset. Oma Eule hugs Brummi and Pip with her wings, everybody is happy and safe at home under the big tree.", 1664, 928, 82, [BRUMMI, PIP, EULE]),
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
