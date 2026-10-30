"""Assets für Level 2 (Abendrot-Hafen): neue Brummi-Referenz nach dem Sprite-Sheet des Nutzers, Anaja, Mama Fuchs,
Gegner, Welt und Story-Bilder. Aufruf: python gen_level2.py refs | jobs [namen...]"""
import sys
from pathlib import Path

from comfy import generate

RAW = Path(__file__).parent / "raw"
CAND = RAW / "cand"
USER = RAW / "user"
FRAMES = USER / "frames"
BRUMMI = RAW / "brummi_ref2.png"
ANAJA = RAW / "anaja_ref.png"
MAMA = RAW / "mama_ref.png"
GRAUPELZ = CAND / "graupelz_101.png"
PIP = CAND / "pip_101.png"
CRAB = RAW / "crab_ref.png"
GULL = RAW / "gull_ref.png"

BG_GREY = "Centered on a plain flat light grey background, nothing else in the image."
STYLE = "Soft shaded 2D cartoon game art with clean dark brown outlines, warm colors, cute and friendly."
SPRITE = f"{BG_GREY} {STYLE}"
BEAR_LOOK = ("a cute chibi teddy bear with warm caramel-brown fur, a very big round head, round ears with light beige inner ears, "
             "big round white eyes with bright blue irises and small eyebrows, a small pale beige horizontal oval muzzle with a tiny dark nose, "
             "a light beige rectangular tummy patch with a small red heart in its center, short stubby arms and legs")
FOX_LOOK = ("a cute little fox girl with bright orange fur, big pointy ears with peach inner ears, big green eyes with eyelashes, "
            "white muzzle, cheeks and chest, black lower legs and paws with pink paw pads, a big fluffy orange tail with a white tip")
BEAR = ("Image 1 is the exact character reference: draw the same teddy bear Brummi with identical face, eye shape, blue irises, muzzle, "
        "caramel-brown fur color, tummy patch with the red heart and identical proportions. Full body, three-quarter view facing to the right. ")
POSE = "Image 2 is a tiny low-resolution pose reference: copy only the body pose of image 2, but draw it in clean high resolution. "
FOX = ("Image 1 is the exact character reference: draw the same little fox girl Anaja with identical face, big green eyes, ears, "
       "orange and white fur pattern, black paws and identical proportions. Full body. ")
MOM = ("Image 1 is the exact character reference: draw the same adult fox lady Mama Fuchs with identical face, green eyes, "
       "fur pattern and teal scarf. Full body. ")
MONSTER = ("Image 1 is the exact character reference: the same big shaggy grey-violet fur monster Graupelz with two small curved horns, "
           "glowing yellow-green eyes and stubby legs. Full body. ")
CRAB_REF = ("Image 1 is the exact character reference: the same small robot crab with the identical red-orange metal shell, "
            "glowing cyan eyes on stalks and dark blue metal claws. ")
GULL_REF = ("Image 1 is the exact character reference: the same small robot seagull with identical white metal body, "
            "dark blue metal wings and glowing cyan eyes. ")
ISO = f"Isolated game asset, {BG_GREY} High quality painterly fantasy game art, vibrant warm sunset colors, soft lighting."
WORLD = ("a magical seaside harbor town at sunset: wooden piers on stilts, a tall red and white striped lighthouse on a rocky cape, "
         "colorful little houses with glowing windows, paper lanterns, sailing boats, golden-orange and pink sky, calm sparkling sea")
SCENE = ("Wide cinematic storybook illustration for a children's game, lush painterly fantasy art, warm golden sunset light, "
         f"{WORLD}. No text, no letters. ")
CAST = "<CAST>"
DESC = {
    BRUMMI: "Brummi, a cute chibi caramel-brown teddy bear with big blue eyes and a red heart on his tummy patch",
    ANAJA: "Anaja, a cute little orange fox girl with big green eyes",
    MAMA: "Mama Fuchs, Anaja's mother, an adult orange fox lady with green eyes and a teal scarf",
    GRAUPELZ: "Graupelz, a big shaggy grey-violet fur monster with small horns",
    PIP: "Pip, a tiny white bunny with a blue scarf",
}


def cast(refs):
    parts = [f"Image {i + 1} is {DESC[r]}." for i, r in enumerate(refs)]
    return (" ".join(parts) + f" Only these {len(refs)} characters appear in the scene, each exactly once, "
            "keep every character exactly as in its own reference image and do not mix their features. ")


# Referenz-Kandidaten: name, prompt, refs, seeds
REFS = [
    ("brummi2", "Image 1 is a tiny low-resolution sprite of the teddy bear Brummi. Redraw exactly this character as a clean high resolution "
                f"full body 2D game character sprite: {BEAR_LOOK}. Keep his exact design, colors, face and proportions from image 1. "
                "Standing relaxed, three-quarter view facing to the right, friendly look. " + SPRITE, [FRAMES / "idle.png"], (101, 202, 303)),
    ("anaja", "Image 1 shows Anaja, a cartoon fox girl. Redraw exactly this character as a clean full body 2D game character sprite: "
              f"{FOX_LOOK}. Keep her exact face, eye color, fur pattern and proportions from image 1. Standing, three-quarter view facing "
              "to the right, sweet friendly smile. No white sticker outline. " + SPRITE, [USER / "anaja_user.png"], (101, 202, 303)),
]
REFS_2 = [
    ("mama", "Image 1 is Anaja, a little fox girl. Draw her mother Mama Fuchs: an adult, taller fox lady in the same design and art style, "
             "same bright orange fur, green eyes with long eyelashes, white muzzle and chest, black paws, wearing a soft teal scarf, "
             "warm caring smile. Full body, standing, three-quarter view facing to the left. " + SPRITE, [ANAJA], (101, 202)),
    ("crab", "2D game enemy character design, a cute small robot crab: round red-orange glossy metal shell with rivets, two glowing cyan eyes "
             "on short metal stalks, two big dark blue metal claws, six thin dark blue metal legs, grumpy frown. Three-quarter side view "
             "facing to the left, full body. " + SPRITE, [], (101, 202)),
    ("gull", "2D game enemy character design, a cute small robot seagull flying: white glossy metal body, dark blue metal wings spread wide, "
             "a yellow metal beak, glowing cyan eyes, a small propeller on its back, grumpy frown. Side view facing to the left, full body. "
             + SPRITE, [], (101, 202)),
]

JOBS = [
    # name, prompt, w, h, seed, refs
    ("bear_idle", BEAR + POSE + "Standing relaxed idle pose, arms at his sides, friendly look. " + SPRITE, 1024, 1024, 21, [BRUMMI, FRAMES / "idle.png"]),
    ("bear_run1", BEAR + POSE + "Running pose, leaning forward. " + SPRITE, 1024, 1024, 22, [BRUMMI, FRAMES / "run_a.png"]),
    ("bear_run2", BEAR + POSE + "Running pose mid-stride, leaning forward. " + SPRITE, 1024, 1024, 23, [BRUMMI, FRAMES / "run_c.png"]),
    ("bear_run3", BEAR + POSE + "Running pose, other leg forward, leaning forward. " + SPRITE, 1024, 1024, 24, [BRUMMI, FRAMES / "run_e.png"]),
    ("bear_jump", BEAR + POSE + "Jumping upwards in the air, legs tucked, excited face. " + SPRITE, 1024, 1024, 25, [BRUMMI, FRAMES / "jump_b.png"]),
    ("bear_fall", BEAR + POSE + "Falling down through the air, arms out to the sides, surprised face. " + SPRITE, 1024, 1024, 26, [BRUMMI, FRAMES / "fall_b.png"]),
    ("bear_punch", BEAR + POSE + "Punch attack: right arm fully stretched forward to the right with a clenched fist, determined face. "
     "No fire, no effects. " + SPRITE, 1024, 1024, 27, [BRUMMI, FRAMES / "punch_a.png"]),
    ("bear_dash", BEAR + POSE + "Dashing forward at high speed, body leaning far forward, determined face. No speed lines, no effects. "
     + SPRITE, 1024, 1024, 28, [BRUMMI, FRAMES / "dash_a.png"]),
    ("bear_hurt", BEAR + POSE + "Getting hit, eyes squeezed shut, wincing. No stars. " + SPRITE, 1024, 1024, 29, [BRUMMI, FRAMES / "hurt_b.png"]),
    ("bear_victory", BEAR + POSE + "Cheering victory pose, both arms raised high, big happy open smile. No sparkles. " + SPRITE, 1024, 1024, 30,
     [BRUMMI, FRAMES / "vic_a.png"]),
    ("bear_special", BEAR + "Shouting NO very loudly and bravely: standing firmly with feet apart, both arms stretched forward with open palms "
     "like a stop sign, mouth wide open, determined brave face. " + SPRITE, 1024, 1024, 32, [BRUMMI]),
    ("bear_shoot", BEAR + "Throwing pose: right arm stretched far forward to the right with an open paw like he just threw something, "
     "left arm pulled back, leaning forward, happy determined face. Nothing in his paws, no effects. " + SPRITE, 1024, 1024, 33, [BRUMMI]),
    ("bear_portrait", "Image 1 is the exact character reference. Close-up portrait of the head of the same teddy bear Brummi, front view, "
     "friendly smile, big blue eyes. " + SPRITE, 1024, 1024, 31, [BRUMMI]),

    ("anaja_sad", FOX + "She is lost and sad: standing with her paws together in front of her chest, teary eyes, ears drooping, looking to the "
     "right. " + SPRITE, 1024, 1024, 41, [ANAJA]),
    ("anaja_run", FOX + "Running happily to the right, side view, tail flowing behind, big smile. " + SPRITE, 1024, 1024, 42, [ANAJA]),
    ("anaja_happy", FOX + "Jumping with joy, both arms raised, eyes closed with a big happy smile. " + SPRITE, 1024, 1024, 43, [ANAJA]),
    ("anaja_portrait", "Image 1 is the exact character reference. Close-up portrait of the head of the same fox girl Anaja, front view, "
     "friendly smile, big green eyes. " + SPRITE, 1024, 1024, 44, [ANAJA]),
    ("mama_wave", MOM + "Waving happily with one raised paw, relieved warm smile, facing to the left. " + SPRITE, 1024, 1024, 45, [MAMA]),

    ("crab_walk", CRAB_REF + "Walking sideways with one claw raised, grumpy. Three-quarter side view facing to the left. " + SPRITE, 1024, 1024, 51, [CRAB]),
    ("crab_happy", CRAB_REF + "Now very happy and friendly: big smile, eyes shown as glowing pink hearts, both claws raised waving. "
     "Facing to the left. " + SPRITE, 1024, 1024, 52, [CRAB]),
    ("gull_fly", GULL_REF + "Flying with wings swept down, grumpy. Side view facing to the left. " + SPRITE, 1024, 1024, 53, [GULL]),
    ("gull_happy", GULL_REF + "Now very happy and friendly: big smile, eyes shown as glowing pink hearts, wings spread up. Side view facing "
     "to the left. " + SPRITE, 1024, 1024, 54, [GULL]),

    ("heart_shot", "A glossy plump pink-red magic heart with a soft white highlight and a warm pink glow, game projectile item. " + ISO, 1024, 1024, 61, []),
    ("lantern", "A wooden harbor lamp post with a glowing warm yellow paper lantern hanging from it, side view, tall. " + ISO, 1024, 1280, 62, []),
    ("barrel", "A sturdy wooden barrel with dark metal rings, front view. " + ISO, 1024, 1024, 63, []),
    ("palm", "A tall curved tropical palm tree with lush green leaves and coconuts, side view. " + ISO, 1024, 1280, 64, []),
    ("shells", "A small sandy tuft with seashells, a pink starfish and beach grass. " + ISO, 1280, 1024, 65, []),
    ("anchor", "An old rusty ship anchor leaning on a coil of thick rope. " + ISO, 1024, 1024, 66, []),
    ("lighthouse", "A small cute red and white striped lighthouse with a glowing warm light on top and a round wooden door at the bottom, "
     "front view, tall. " + ISO, 1024, 1536, 67, []),
    ("pier", "Side view of a straight level wooden pier walkway: horizontal wooden planks on thick wooden stilts, with a simple rope railing. "
     + ISO, 2048, 768, 68, []),
    ("sand1", "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level top of golden sand with a little beach grass "
     "and small shells, below it a tall warm orange sandstone cliff face. " + ISO, 1024, 1280, 71, []),
    ("sand2", "Side view cross-section of a chunk of terrain for a 2D platformer: a flat level top of golden sand with tufts of beach grass, "
     "below it a tall layered reddish-brown rock cliff face with small barnacles. " + ISO, 1024, 1280, 72, []),
    ("raft", "A small floating wooden raft platform for a 2D platformer, side view, flat level top made of wooden planks tied with rope, "
     "with an old floating barrel and a little seaweed underneath. " + ISO, 1280, 1024, 73, []),
    ("bg_boat", "A distant small wooden sailing boat with a white sail on calm water, soft hazy sunset colors. " + ISO, 1024, 1024, 74, []),
    ("bg_rock", "A distant rocky sea stack island with a few palm trees and a tiny glowing lighthouse, soft hazy sunset colors. " + ISO, 1024, 1024, 75, []),
    ("bg_sky2", "Lush painterly 2D fantasy platformer game background art, vibrant saturated colors, dreamy atmosphere. Wide panorama of "
     f"{WORLD}, distant mountains with a fairytale castle, big glowing setting sun on the horizon, pink and orange clouds. "
     "No characters, no foreground ground.", 2048, 1024, 81, []),

    ("graupelz_disguise", MONSTER + "He wears a blue sailor cap and holds a little sign with a fox drawing as a fake friendly disguise, "
     "smiling fake friendly, beckoning with one paw. " + SPRITE, 1024, 1024, 91, [GRAUPELZ]),

    ("l2_intro1", SCENE + CAST + "Brummi and Pip arrive happily at the harbor festival on a wooden pier, lanterns everywhere, they look around in "
     "amazement.", 1664, 928, 101, [BRUMMI, PIP]),
    ("l2_intro2", SCENE + CAST + "On a wooden pier the little fox girl Anaja stands alone and cries, she has lost her mother. Brummi walks up to "
     "her kindly.", 1664, 928, 102, [BRUMMI, ANAJA]),
    ("l2_intro3", SCENE + CAST + "Brummi and Anaja sit together on the edge of the pier. Anaja points to the tall lighthouse far away on the "
     "rocky cape: that is the meeting point she agreed with her mother.", 1664, 928, 103, [BRUMMI, ANAJA]),
    ("l2_intro4", SCENE + CAST + "Graupelz, wearing a blue sailor cap as a disguise, bends down to Anaja with a fake friendly grin and beckons "
     "her to come with him. Brummi steps in front of Anaja protectively. Slightly mysterious mood with purple shadows.", 1664, 928, 104,
     [BRUMMI, ANAJA, GRAUPELZ]),
    ("l2_intro5", SCENE + CAST + "Anaja shows Brummi her magic: little glowing pink hearts float up from her paws. Brummi watches amazed, "
     "magical sparkles.", 1664, 928, 105, [BRUMMI, ANAJA]),
    ("l2_intro6", SCENE + CAST + "Brummi and Anaja walk together hand in hand along the sandy coast path towards the distant lighthouse, "
     "seen from behind at an angle, full of courage.", 1664, 928, 106, [BRUMMI, ANAJA]),
    ("l2_outro1", SCENE + CAST + "At the foot of the lighthouse, Brummi throws a glowing pink heart. The monster Graupelz runs away to the right "
     "in panic, his sailor cap flying off.", 1664, 928, 111, [BRUMMI, GRAUPELZ]),
    ("l2_outro2", SCENE + CAST + "In front of the lighthouse, Anaja hugs her mother tightly, both very happy. Brummi stands next to them and "
     "smiles proudly. Paper lanterns and fireworks in the sky.", 1664, 928, 112, [BRUMMI, ANAJA, MAMA]),
]


def run_refs(refs):
    for name, prompt, images, seeds in refs:
        for seed in seeds:
            out = CAND / f"{name}_{seed}.png"
            if not out.exists():
                print("generating", out.name, flush=True)
                generate(prompt, out, 1024, 1024, seed, images)


if __name__ == "__main__":
    stage, only = sys.argv[1], set(sys.argv[2:])
    if stage == "refs":
        run_refs(REFS)
    elif stage == "refs2":
        run_refs(REFS_2)
    else:
        for name, prompt, w, h, seed, refs in JOBS:
            out = RAW / f"{name}.png"
            if out.exists() or (only and name not in only):
                continue
            print("generating", name, flush=True)
            generate(prompt.replace(CAST, cast(refs)) if CAST in prompt else prompt, out, w, h, seed, refs)
    print("done", flush=True)
