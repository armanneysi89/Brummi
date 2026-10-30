"""Erzeugt Referenz-Kandidaten für die Hauptfiguren (Auswahl danach von Hand)."""
import sys
from pathlib import Path

from comfy import generate

OUT = Path(__file__).parent / "raw" / "cand"
STYLE = ("Flat 2D cartoon game character sprite, cel shading, bold dark brown outlines, clean simple shapes, vibrant colors, "
         "not 3D, not plush, not realistic. Full body, standing, centered on a plain flat light grey background, nothing else.")

CANDIDATES = {
    "brummi": "A cute chibi teddy bear named Brummi in three-quarter view facing right. Very big round head (almost half of the body height), "
              "small round ears with light tan inner ears, large round eyes with white sclera, bright sky-blue irises and black pupils looking sideways, "
              "a big pale tan oval muzzle on the lower face with a small dark brown nose on top and a tiny shy smile, "
              "medium chestnut brown fur with a few fur tufts at the edges, a large light beige oval belly patch, a tiny red heart on the upper chest, "
              "short stubby arms hanging down, short stubby legs, slightly pigeon-toed. " + STYLE,
    "graupelz": "A big shaggy fairy tale monster called Graupelz: a tall bulky body covered in long dusty grey-violet shaggy fur hanging down like a cloak, "
                "two small curved pointy horns on top of the head, glowing yellow-green eyes, a wide fake friendly grin, short stubby legs peeking out under the fur, "
                "long furry arms, holding a big colorful swirl lollipop to tempt children. Mysterious but not too scary, suitable for a children's game. " + STYLE,
    "pip": "A tiny cute white bunny named Pip with long ears with pink inner ears, big round brown eyes, a small pink nose, a little blue scarf, "
           "fluffy round tail, standing upright, sweet and innocent. " + STYLE,
    "eule": "A kind wise old grandmother owl called Oma Eule with soft brown and cream feathers, big round golden eyes behind small round glasses, "
            "a knitted purple shawl, holding a small glowing blue lantern, warm and trustworthy smile. " + STYLE,
}

if __name__ == "__main__":
    names = sys.argv[1:] or list(CANDIDATES)
    for name in names:
        for seed in (101, 202, 303):
            out = OUT / f"{name}_{seed}.png"
            if not out.exists():
                print("generating", out.name, flush=True)
                generate(CANDIDATES[name], out, 1024, 1024, seed)
    print("done", flush=True)
