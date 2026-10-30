"""Erzeugt alle Roh-Assets für Level 1 über ComfyUI. Bereits vorhandene Dateien werden übersprungen."""
import sys
from pathlib import Path

from comfy import generate

RAW = Path(__file__).parent / "raw"
REF = RAW / "brummi_ref.png"
SHEEP = RAW / "sheep_ref.png"

SPRITE = "Centered on a plain flat light grey background, nothing else in the image. High quality painterly cartoon fantasy game art, vibrant warm colors, soft lighting, clean dark outline."
BEAR = ("Use image 1 as the exact character reference: the same cute brown teddy bear Brummi with identical face, big blue eyes, "
        "tan muzzle, round ears, beige belly patch with red heart, same colors and proportions. Full body, three-quarter side view facing to the right. ")
SHEEP_REF = ("Use image 1 as the exact character reference: the same small robot sheep with identical fluffy white wool, dark visor face, "
             "glowing cyan eyes and dark blue metal legs. Three-quarter side view facing to the left. ")
BG = "Lush painterly 2D fantasy platformer game background art, vibrant saturated colors, warm soft cinematic sunlight, highly detailed, dreamy atmosphere."
ISO = "Isolated game asset, centered on a plain flat light grey background, nothing else. High quality painterly fantasy game art, vibrant colors, soft lighting."

JOBS = [
    # name, prompt, w, h, seed, refs
    ("sheep_ref", "2D game enemy character design, a cute small robot sheep: round body of very fluffy white cloud-like wool, a round glossy dark navy visor face with two big glowing cyan eyes, short dark blue metal legs, small curled dark blue metal horns with glowing cyan tips. Three-quarter side view facing to the left, full body. " + SPRITE, 1024, 1024, 3, []),

    ("bear_idle", BEAR + "Standing relaxed idle pose, arms at his sides, friendly smile. " + SPRITE, 1024, 1024, 21, [REF]),
    ("bear_run1", BEAR + "Running pose: right leg stretched far forward, left leg pushed back, left arm forward, right arm back, body leaning forward. " + SPRITE, 1024, 1024, 22, [REF]),
    ("bear_run2", BEAR + "Running pose mid-stride: both feet off the ground, legs passing each other under the body, arms bent, body leaning forward. " + SPRITE, 1024, 1024, 23, [REF]),
    ("bear_run3", BEAR + "Running pose: left leg stretched far forward, right leg pushed back, right arm forward, left arm back, body leaning forward. " + SPRITE, 1024, 1024, 24, [REF]),
    ("bear_jump", BEAR + "Jumping upwards in the air, both arms raised up high, legs tucked under the body, excited expression. " + SPRITE, 1024, 1024, 25, [REF]),
    ("bear_fall", BEAR + "Falling down through the air, arms spread out wide to the sides, legs dangling, surprised open mouth. " + SPRITE, 1024, 1024, 26, [REF]),
    ("bear_punch", BEAR + "Powerful punch attack: right arm fully stretched forward to the right with a clenched fist, left arm pulled back, determined face, leaning into the punch. " + SPRITE, 1024, 1024, 27, [REF]),
    ("bear_dash", BEAR + "Dashing forward at high speed: body leaning far forward horizontally, arms stretched back behind him, legs stretched back, determined face. " + SPRITE, 1024, 1024, 28, [REF]),
    ("bear_hurt", BEAR + "Getting hit and recoiling backwards, eyes squeezed shut, wincing, arms flung up, leaning back. " + SPRITE, 1024, 1024, 29, [REF]),
    ("bear_victory", BEAR + "Cheering victory pose, both arms raised high in the air, big happy open smile, eyes closed with joy. " + SPRITE, 1024, 1024, 30, [REF]),
    ("bear_portrait", "Use image 1 as the exact character reference. Close-up portrait of the head of the same cute brown teddy bear Brummi, front view, friendly smile, big blue eyes. " + SPRITE, 1024, 1024, 31, [REF]),

    ("sheep_walk", SHEEP_REF + "Walking pose with one front leg lifted. " + SPRITE, 1024, 1024, 41, [SHEEP]),
    ("sheep_hit", SHEEP_REF + "Getting hit, dizzy, eyes shown as glowing cyan swirls, tilted backwards, wool puffed up. " + SPRITE, 1024, 1024, 42, [SHEEP]),

    ("coin", "A shiny golden coin with an embossed bear paw print in the center, front view, round. " + ISO, 1024, 1024, 51, []),
    ("heart", "A glossy plump red heart icon with a soft white highlight, game UI item. " + ISO, 1024, 1024, 52, []),
    ("crystal", "A cluster of glowing light blue magic crystals growing from a small mossy rock. " + ISO, 1024, 1024, 53, []),
    ("mushroom", "A cute glowing orange fantasy mushroom with a spotted cap on a small tuft of grass. " + ISO, 1024, 1024, 54, []),
    ("glowflower", "A tall glowing light blue magical flower with luminous petals and green leaves. " + ISO, 1024, 1024, 55, []),
    ("crate", "A sturdy wooden crate with metal corner brackets, front view. " + ISO, 1024, 1024, 56, []),
    ("sign", "A wooden signpost with a single wooden arrow board pointing to the right, blank board without any text, standing on a little grass tuft. " + ISO, 1024, 1024, 57, []),
    ("portal", "An ancient mossy stone gate portal with ivy, a glowing cyan magical rune circle in the middle of the gate, front view, tall. " + ISO, 1024, 1280, 58, []),
    ("bridge", "Side view of a wooden rope bridge, horizontal wooden planks hanging between two wooden posts with ropes, straight and level. " + ISO, 2048, 768, 59, []),
    ("ground1", "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level lush green grass top with small flowers, below it a tall mossy rocky earth cliff face. " + ISO, 1024, 1280, 61, []),
    ("ground2", "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level lush green grass top with ferns, below it a tall grey-brown rocky cliff face with hanging ivy. " + ISO, 1024, 1280, 62, []),
    ("island", "A small floating rock island for a 2D platformer, side view, flat level lush grass top, rocky underside tapering to a point with hanging roots and vines. " + ISO, 1280, 1024, 63, []),
    ("bush", "A lush round green bush with small pink and glowing blue flowers and ferns. " + ISO, 1280, 1024, 64, []),
    ("tree", "A huge ancient fantasy tree with a thick twisted trunk, big roots and a lush green canopy with glowing yellow fireflies, side view. " + ISO, 1024, 1280, 65, []),
    ("bg_island1", "A distant floating rock island with green trees on top and a thin waterfall pouring down from it, soft hazy colors. " + ISO, 1024, 1024, 71, []),
    ("bg_island2", "A distant floating rock island with a small fairytale tower and trees on top, hanging vines, soft hazy colors. " + ISO, 1024, 1024, 72, []),
    ("bg_sky", BG + " Wide panorama of a magical valley: a white fairytale castle with blue spires on a distant cliff, many floating islands with waterfalls, tall waterfalls pouring into a misty blue river valley, distant blue mountains, bright blue sky with big fluffy white clouds. No characters, no foreground ground.", 2048, 1024, 81, []),
]

if __name__ == "__main__":
    only = set(sys.argv[1:])
    for name, prompt, w, h, seed, refs in JOBS:
        out = RAW / f"{name}.png"
        if out.exists() or (only and name not in only):
            continue
        print("generating", name, flush=True)
        generate(prompt, out, w, h, seed, refs)
    print("done", flush=True)
