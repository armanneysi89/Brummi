extends Level

## Level 2 – Die Abendrot-Küste: Anaja hat ihre Mama verloren. Treffpunkt ist der Leuchtturm.

const G := Platform.Kind.GROUND
const I := Platform.Kind.ISLAND
const B := Platform.Kind.BRIDGE

const PLATFORMS := [
	[G, 0, 760, 1700, Vector2.ZERO],
	[G, 1700, 760, 1500, Vector2.ZERO],
	[B, 3200, 760, 620, Vector2.ZERO],
	[I, 3980, 700, 260, Vector2.ZERO],
	[I, 4380, 640, 260, Vector2(0, -90)],
	[I, 4780, 700, 260, Vector2.ZERO],
	[G, 5150, 760, 1700, Vector2.ZERO],
	[B, 6850, 760, 560, Vector2.ZERO],
	[I, 7560, 700, 240, Vector2(300, 0)],
	[I, 8240, 640, 240, Vector2.ZERO],
	[G, 8650, 760, 1750, Vector2.ZERO],
	[B, 10400, 760, 520, Vector2.ZERO],
	[G, 10920, 760, 2280, Vector2.ZERO],
]

const RULES := [
	[1500, 600, "Wenn du dich verlaufen hast: Bleib stehen und lauf nicht kreuz und quer herum."],
	[4510, 470, "Macht vorher einen Treffpunkt aus – dort findet ihr euch ganz sicher wieder."],
	[6450, 620, "Hol dir Hilfe bei jemandem, der dort arbeitet – an der Kasse, bei der Polizei – oder bei einer Mama mit Kindern."],
	[8360, 470, "Lerne deinen Namen und deine Adresse auswendig – und wenn du kannst, Mamas oder Papas Telefonnummer."],
	[10650, 580, "Auch wenn jemand sagt „Deine Mama schickt mich“: Geh nie mit Fremden mit!"],
]

const SIGNS := [
	[420, 760, "Da vorne weint jemand … Lauf hin und schau, ob du helfen kannst!"],
	[2050, 760, "Eine Robo-Krabbe! Wirf ein Herz mit L oder C – dann wird sie wieder lieb."],
	[3120, 760, "Auf dem Steg kreisen Robo-Möwen. Wirf Herzen, wenn sie herabstoßen!"],
	[3900, 700, "Spring von Floß zu Floß. Das mittlere schaukelt auf und ab."],
	[5350, 760, "Achtung, Graupelz ist verkleidet! Wenn er euch locken will: Drück E und ruf laut NEIN!"],
	[11000, 760, "Der Leuchtturm! Doch Graupelz versperrt den Weg. Erst NEIN rufen (E) – dann wirken deine Herzen."],
]

# [Art, x, y (Fußpunkt bzw. Flughöhe), Größe/Radius, Leben, Patrouillenradius]
const ENEMIES := [
	["crab", 2500, 760, 1.0, 1, 160],
	["gull", 3500, 520, 0, 0, 240],
	["crab", 5700, 760, 1.0, 2, 150],
	["gull", 7100, 500, 0, 0, 260],
	["crab", 9000, 760, 1.0, 2, 160],
	["gull", 9350, 480, 0, 0, 220],
	["crab", 9700, 760, 1.2, 2, 150],
	["crab", 10150, 760, 1.0, 2, 120],
	["gull", 10650, 500, 0, 0, 220],
]

const CHECKPOINTS := [Vector2(5300, 760), Vector2(8800, 760), Vector2(11000, 760)]
const CRATES := [Vector2(2950, 760), Vector2(3040, 760), Vector2(2995, 670), Vector2(9480, 760), Vector2(6200, 760)]

const COIN_ROWS := [
	[650, 690, 3, 80], [1250, 640, 3, 80], [2200, 690, 3, 80], [2995, 560, 1, 0],
	[3350, 650, 4, 110], [4110, 610, 1, 0], [4430, 470, 3, 80], [4910, 610, 1, 0],
	[5500, 690, 3, 80], [6050, 600, 3, 80], [6950, 650, 4, 100],
	[7700, 600, 3, 90], [8320, 540, 2, 80], [8900, 690, 3, 80], [9480, 560, 1, 0],
	[10450, 650, 4, 100], [11300, 690, 4, 80],
]

const DECOR := [
	["palm", 150, 770, 760, false, -3], ["shells", 560, 770, 70, false, 1], ["lantern", 760, 770, 300, false, -1],
	["barrel", 1150, 770, 90, false, -1], ["anchor", 1650, 770, 120, true, -1],
	["lantern", 1900, 770, 300, true, -1], ["shells", 2350, 770, 60, true, 1], ["palm", 2750, 770, 700, true, -3],
	["lantern", 3460, 770, 280, false, -1], ["lantern", 7130, 770, 280, true, -1], ["lantern", 10660, 770, 280, false, -1],
	["palm", 5250, 770, 720, false, -3], ["shells", 5900, 770, 70, false, 1], ["lantern", 6300, 770, 300, false, -1],
	["anchor", 6700, 770, 110, false, -1],
	["palm", 8750, 770, 760, true, -3], ["shells", 9250, 770, 60, false, 1], ["lantern", 9900, 770, 300, true, -1],
	["palm", 11150, 770, 700, false, -3], ["lantern", 11700, 770, 300, false, -1], ["shells", 12300, 770, 70, true, 1],
	["lantern", 13050, 770, 300, true, -1],
]

const SCOUT_LINES := [
	"Hallo ihr zwei! Deine Mama schickt mich!",
	"Kommt mit, ich bring euch zu ihr!",
	"Ich kenne eine Abkürzung …",
]
const BOSS_LINES := [
	"Ich bin ein Freund deiner Mama!",
	"Sie wartet hinter den Felsen – kommt mit!",
	"Psst … das bleibt unser Geheimnis!",
	"Ich hab auch Muscheln und Bonbons für euch!",
]
const DISGUISE: Texture2D = preload("res://assets/monster/graupelz_disguise.png")
const MAMA_TEX: Texture2D = preload("res://assets/characters/mama_wave.png")
const LIGHTHOUSE: Texture2D = preload("res://assets/objects/lighthouse.png")


## Meer in den Lücken zwischen den Plattformen, mit sanften Wellenlinien.
class _Sea extends Node2D:
	var width := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var top := 930.0
		var poly := PackedVector2Array([Vector2(-200, top), Vector2(width + 200, top), Vector2(width + 200, 1700), Vector2(-200, 1700)])
		draw_polygon(poly, PackedColorArray([Color("e88a6a"), Color("e88a6a"), Color("2b3f6b"), Color("2b3f6b")]))
		for row in 5:
			var y := top + 14.0 + row * 34.0
			var pts := PackedVector2Array()
			var x := -200.0
			while x < width + 200.0:
				pts.append(Vector2(x, y + sin(x * 0.012 + _t * (1.4 - row * 0.15) + row) * 6.0))
				x += 40.0
			draw_polyline(pts, Color(1.0, 0.9, 0.75, 0.35 - row * 0.06), 3.0)


var _anaja: Anaja


func _init() -> void:
	level_number = 2
	level_end = 13200.0
	goal_x = 12750.0
	music = "level2"
	title = "LEVEL 2 – Die Abendrot-Küste"
	subtitle = "Bring Anaja zum Leuchtturm!"
	crate_tex = preload("res://assets/objects/barrel.png")
	platforms = PLATFORMS
	rules = RULES
	signs = SIGNS
	enemies = ENEMIES
	checkpoints = CHECKPOINTS
	crates = CRATES
	coin_rows = COIN_ROWS
	decor = DECOR


func _theme_background(bg: Background) -> void:
	bg.sky = preload("res://assets/background/bg_sky2.png")
	bg.props = [preload("res://assets/background/bg_boat.png"), preload("res://assets/background/bg_rock.png")]
	bg.prop_y = Vector2(560.0, 700.0)
	bg.prop_scale = Vector2(0.22, 0.38)
	bg.mist_color = Color(1.0, 0.72, 0.6, 0.9)
	bg.fly_color = Color(1.0, 0.75, 0.45)
	var sea := _Sea.new()
	sea.width = level_end
	sea.z_index = -4
	add_child(sea)


func _theme_platform(plat: Platform) -> void:
	plat.ground_tex = [preload("res://assets/terrain/sand1.png"), preload("res://assets/terrain/sand2.png")]
	plat.island_tex = preload("res://assets/terrain/raft.png")
	plat.bridge_tex = preload("res://assets/terrain/pier.png")
	plat.fill_color = Color("6b4330")


func _build_enemies() -> void:
	for e in enemies:
		if e[0] == "gull":
			var gull := RoboGull.new()
			gull.position = Vector2(e[1], e[2])
			gull.patrol_range = e[5]
			add_child(gull)
		else:
			var crab := RoboCrab.new()
			crab.position = Vector2(e[1], e[2])
			crab.size = e[3]
			crab.max_hp = e[4]
			crab.patrol_range = e[5]
			add_child(crab)


func _build_story() -> void:
	_anaja = Anaja.new()
	_anaja.position = Vector2(950, 770)
	_anaja.z_index = 1
	_anaja.met.connect(_on_anaja_met)
	add_child(_anaja)

	var scout := Graupelz.new()
	scout.boss = false
	scout.tex_idle = DISGUISE
	scout.bait = null
	scout.lines = SCOUT_LINES
	scout.position = Vector2(6000, 760)
	add_child(scout)
	_monsters.append(scout)

	var boss := Graupelz.new()
	boss.tex_idle = DISGUISE
	boss.bait = null
	boss.lines = BOSS_LINES
	boss.position = Vector2(11900, 760)
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	_monsters.append(boss)

	var mama := HintSign.new()
	mama.tex = MAMA_TEX
	mama.height = 175.0
	mama.position = Vector2(goal_x + 230.0, 770)
	mama.hint = "Anaja! Mein Schatz! Danke, Brummi – du hast genau richtig gehandelt. Kommt, wir gehen in den Leuchtturm!"
	mama.z_index = 1
	add_child(mama)

	_portal = Portal.new()
	_portal.tex = LIGHTHOUSE
	_portal.height = 560.0
	_portal.glow_at = 0.86
	_portal.position = Vector2(goal_x, 770)
	_portal.open = false
	_portal.reached.connect(_on_goal_reached)
	add_child(_portal)


func _on_anaja_met() -> void:
	_player.can_shoot = true
	Sound.sfx("learn")
	_hud.show_message("Neue Fähigkeit: Herz-Wurf!", "Anaja hat dir gezeigt, wie man Herzen wirft. Drück L oder C – Herzen machen grimmige Robo-Tiere wieder lieb!", 7.0)


func _on_boss_defeated() -> void:
	_anaja.go_home(goal_x + 140.0)
	_portal.open = true
	Sound.sfx("fanfare")
	get_tree().create_timer(1.2).timeout.connect(func() -> void: Sound.sfx("portal_open"))
	_hud.show_message("Geschafft!", "Graupelz ist weggelaufen. Und schau – da vorne am Leuchtturm wartet Anajas Mama! Geh mit ihnen in den Leuchtturm.", 6.0)
