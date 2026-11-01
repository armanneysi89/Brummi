extends Level

const G := Platform.Kind.GROUND
const I := Platform.Kind.ISLAND
const B := Platform.Kind.BRIDGE

# [Art, x, y (Oberkante), Breite, Bewegung]
const PLATFORMS := [
	[G, 0, 760, 1500, Vector2.ZERO],
	[B, 1500, 760, 520, Vector2.ZERO],
	[G, 2020, 760, 1300, Vector2.ZERO],
	[I, 3470, 700, 260, Vector2.ZERO],
	[I, 3860, 610, 260, Vector2.ZERO],
	[I, 4250, 700, 260, Vector2.ZERO],
	[G, 4660, 760, 1900, Vector2.ZERO],
	[I, 6720, 700, 240, Vector2.ZERO],
	[I, 7080, 660, 240, Vector2(320, 0)],
	[G, 7800, 760, 1700, Vector2.ZERO],
	[B, 9500, 760, 500, Vector2.ZERO],
	[G, 10000, 760, 2400, Vector2.ZERO],
]

const RULES := [
	[1200, 600, "Geh nie mit Fremden mit – auch nicht, wenn sie nett tun oder dich kennen wollen."],
	[2995, 520, "Nimm keine Geschenke oder Süßigkeiten von Fremden an."],
	[6350, 640, "Wenn dich jemand locken will: Ruf laut NEIN, lauf weg und hol dir Hilfe."],
	[8950, 620, "Erzähl es immer einem Erwachsenen, dem du vertraust – zum Beispiel Mama, Papa oder deiner Erzieherin."],
	[9750, 580, "Geheimnisse, die dir Angst oder Bauchweh machen, darfst du immer weitersagen."],
]

# [x, y (Fußpunkt), Text]
const SIGNS := [
	[950, 760, "Leertaste: springen. Halte sie länger für höhere Sprünge."],
	[2180, 760, "Ein Robo-Schaf von Graupelz! Schlag es mit J oder X."],
	[3240, 760, "Spring über die schwebenden Inseln. Mit K oder Shift sprintest du."],
	[5000, 760, "Achtung! Hier lauert Graupelz. Wenn er dich lockt: Drück E und ruf laut NEIN!"],
	[6620, 760, "Die Insel schwebt hin und her – warte auf den richtigen Moment."],
	[10150, 760, "Graupelz hält Pip gefangen! Hauen allein hilft nicht: Ruf zuerst NEIN (E) – dann ist er wehrlos."],
]

# [x, y (Fußpunkt), Größe, Leben, Patrouillenradius]
const ENEMIES := [
	[2700, 760, 1.0, 1, 150],
	[5250, 760, 1.0, 2, 160],
	[8300, 760, 1.0, 2, 160],
	[8700, 760, 1.0, 2, 160],
	[9200, 760, 1.4, 3, 120],
]

const CHECKPOINTS := [Vector2(4780, 760), Vector2(7920, 760), Vector2(10080, 760)]
const CRATES := [Vector2(1250, 760), Vector2(2950, 760), Vector2(3040, 760), Vector2(2995, 670), Vector2(8480, 760), Vector2(8570, 760)]

# Münzreihen: [x, y, Anzahl, Abstand]
const COIN_ROWS := [
	[700, 690, 3, 80], [1180, 640, 3, 70], [1640, 650, 3, 120],
	[2400, 690, 3, 80], [3600, 610, 1, 0], [3795, 520, 3, 95], [4380, 610, 1, 0],
	[5050, 690, 3, 80], [5500, 600, 3, 80], [6050, 690, 3, 80],
	[6840, 610, 1, 0], [7200, 560, 3, 100],
	[8050, 690, 3, 80], [8525, 560, 2, 90], [9100, 600, 3, 80],
	[9600, 650, 4, 100], [10400, 690, 4, 80],
]

# [Art, x, y (Fußpunkt), Höhe, gespiegelt, z]
const DECOR := [
	["tree", 120, 770, 900, false, -3], ["bush", 620, 770, 170, false, 1], ["glowflower", 760, 770, 150, false, -1],
	["mushroom", 1100, 770, 80, false, -1], ["crystal", 1420, 770, 140, false, -1],
	["bush", 2080, 770, 150, true, 1], ["glowflower", 2560, 770, 170, true, -1], ["mushroom", 3200, 770, 90, true, -1],
	["tree", 4720, 770, 760, true, -3], ["glowflower", 5150, 770, 160, false, -1], ["bush", 5750, 770, 160, false, 1],
	["mushroom", 6200, 770, 70, false, -1], ["crystal", 6480, 770, 150, true, -1],
	["tree", 8000, 770, 820, false, -3], ["bush", 8800, 770, 170, true, 1], ["glowflower", 9350, 770, 160, false, -1],
	["mushroom", 3940, 618, 60, false, -1], ["crystal", 10500, 770, 150, false, -1],
	["tree", 11000, 770, 900, true, -3], ["glowflower", 11500, 770, 180, true, -1], ["bush", 12300, 770, 180, false, 1],
]

var _pip: Pip


func _init() -> void:
	level_number = 1
	title = "LEVEL 1 – Das Tal der Lichter"
	subtitle = "Bring Pip sicher nach Hause!"
	platforms = PLATFORMS
	rules = RULES
	signs = SIGNS
	enemies = ENEMIES
	checkpoints = CHECKPOINTS
	crates = CRATES
	coin_rows = COIN_ROWS
	decor = DECOR


func _build_story() -> void:
	_add_eule(Vector2(470, 770), "Bring Pip sicher nach Hause, Brummi! Und denk dran: Geh nie mit Fremden mit. Sammle unterwegs die goldenen Mut-Sterne!")

	var scout := Graupelz.new()
	scout.boss = false
	scout.position = Vector2(5900, 760)
	add_child(scout)
	_monsters.append(scout)

	var boss := Graupelz.new()
	boss.position = Vector2(11150, 760)
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	_monsters.append(boss)

	_pip = Pip.new()
	_pip.position = Vector2(11650, 770)
	_pip.z_index = 1
	add_child(_pip)

	_add_eule(Vector2(goal_x + 190.0, 770), "Oh Brummi, du warst so mutig! Komm mit Pip durch das Portal – wir gehen nach Hause.", true)

	_portal = Portal.new()
	_portal.position = Vector2(goal_x, 770)
	_portal.open = false
	_portal.reached.connect(_on_goal_reached)
	add_child(_portal)


func _on_boss_defeated() -> void:
	_pip.free_pip()
	_portal.open = true
	Sound.sfx("fanfare")
	get_tree().create_timer(1.2).timeout.connect(func() -> void: Sound.sfx("portal_open"))
	_hud.show_message("Pip ist frei!", "Graupelz ist weggelaufen – gegen ein lautes NEIN hat er keine Chance. Bring Pip zu Oma Eule ins Portal!", 6.0)
