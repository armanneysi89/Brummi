# Brummi

2D-Jump'n'Run für Kinder, gebaut mit Godot 4.7 (GL Compatibility). Brummi, ein mutiger Bär, bringt Pip und Anaja sicher nach Hause, sammelt Mut-Regeln und ruft laut „NEIN!“, wenn Graupelz ihn locken will.

## Levels

1. Das Tal der Lichter – Bring Pip sicher nach Hause!
2. Die Abendrot-Küste – Bring Anaja zum Leuchtturm! (Herz-Wurf, Robo-Krabben und -Möwen)

Level 2 wird nach Level 1 freigeschaltet.

## Steuerung

| Aktion | Tastatur | Touch |
|---|---|---|
| Laufen | A / D, Pfeile | Analogstick (linke Bildschirmhälfte) |
| Springen | Leertaste, W, Pfeil hoch | Sprung |
| Schlagen | J, X | Hau! |
| Sprinten | K, Shift | Dash |
| NEIN rufen | E, N | NEIN! |
| Herz werfen (ab Level 2) | L, C, H | Herz |
| Neustart | R | Neu |
| Ton an/aus | M | – |

Die Touch-Steuerung erscheint auf Smartphones (auch im Browser) automatisch. Auf dem Desktop erzwingt man sie mit `-- --touch`.

## Entwickeln

Godot 4.7 öffnen und das Projekt-Verzeichnis laden, oder direkt starten:

```sh
godot --path .
```

Level direkt starten, z. B. ab einer X-Position: `godot --path . levels/level_1.tscn -- --x=3000`. Das Outro startet mit `scenes/story.tscn -- --outro`.

## Projektstruktur

- `scripts/` – Spiellogik (`player.gd`, `level.gd`, `hud.gd`, `touch_controls.gd`, …)
- `levels/` – Level-Daten, erben von `scripts/level.gd`
- `scenes/` – Hauptmenü und Story
- `assets/` – Grafiken und Audio
- `tools/` – Python-Werkzeuge zur Asset-Erzeugung (ComfyUI, Audiosynthese) und `build_release.sh`

## Release bauen

Benötigt Godot-Export-Templates 4.7.2 und für Android das Android-SDK samt Java-SDK-Pfad in den Editoreinstellungen.

```sh
tools/build_release.sh
```

Exportiert Linux (x86_64, ARM64), Windows (x86_64, ARM64), macOS, Web und Android nach `builds/<plattform>/`. Die Web-Version braucht einen Webserver mit HTTPS oder `localhost`.
