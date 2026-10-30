extends Node2D

const LEVEL_END := 12400.0
const CAMERA_BOTTOM := 1200
const START := Vector2(260, 760)
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

const GOAL_X := 12150.0
const EULE_TEX: Texture2D = preload("res://assets/characters/eule.png")
const CRATE_TEX: Texture2D = preload("res://assets/objects/crate.png")

var _player: Brummi
var _hud: Hud
var _portal: Portal
var _pip: Pip
var _monsters: Array[Graupelz] = []
var _collected := 0
var _rule_index := 0
var _was_lured := false


func _ready() -> void:
	Sound.play_music("level")
	var bg := Background.new()
	bg.level_width = LEVEL_END
	bg.camera_bottom = CAMERA_BOTTOM
	add_child(bg)
	_build_platforms()
	_build_walls()
	_build_decor()
	_build_crates()
	_build_hud()
	_build_pickups()
	_build_signs()
	_build_enemies()
	_build_story()
	_build_player()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _process(_delta: float) -> void:
	var lured := false
	for m in _monsters:
		if is_instance_valid(m) and m.player_is_lured():
			lured = true
	_hud.lured = lured
	if lured != _was_lured:
		_was_lured = lured
		Sound.set_tension(lured)
		if lured:
			Sound.sfx("alert")


func _build_platforms() -> void:
	for p in PLATFORMS:
		var plat := Platform.new()
		plat.kind = p[0]
		plat.position = Vector2(p[1], p[2])
		plat.size = Vector2(p[3], 700)
		plat.move = p[4]
		add_child(plat)


func _build_walls() -> void:
	for x in [-30.0, LEVEL_END]:
		var wall := StaticBody2D.new()
		wall.position = Vector2(x, -1000)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(30, 4000)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(15, 2000)
		wall.add_child(cs)
		add_child(wall)


func _build_decor() -> void:
	for d in DECOR:
		var decor := Decor.new()
		decor.kind = d[0]
		decor.position = Vector2(d[1], d[2])
		decor.height = d[3]
		decor.flip = d[4]
		decor.z_index = d[5]
		add_child(decor)


func _build_crates() -> void:
	for pos in CRATES:
		var crate := StaticBody2D.new()
		crate.position = pos
		var shape := RectangleShape2D.new()
		shape.size = Vector2(88, 88)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(0, -44)
		crate.add_child(cs)
		var sp := Sprite2D.new()
		sp.texture = CRATE_TEX
		var s := 92.0 / CRATE_TEX.get_height()
		sp.scale = Vector2(s, s)
		sp.position = Vector2(0, -45)
		crate.add_child(sp)
		add_child(crate)


func _build_hud() -> void:
	_hud = Hud.new()
	_hud.level_width = LEVEL_END
	_hud.goal_x = GOAL_X
	_hud.total_stars = RULES.size()
	for p in PLATFORMS:
		_hud.map_rects.append(Rect2(p[1], p[2], p[3], 0))
	add_child(_hud)


func _build_pickups() -> void:
	for row in COIN_ROWS:
		for i in row[2]:
			var coin := Coin.new()
			coin.position = Vector2(row[0] + i * row[3], row[1])
			coin.collected.connect(_on_coin_collected)
			add_child(coin)
			_hud.total_coins += 1
	for r in RULES:
		var star := RuleStar.new()
		star.position = Vector2(r[0], r[1])
		star.text = r[2]
		star.collected.connect(_on_rule_collected)
		add_child(star)
	for pos in CHECKPOINTS:
		var cp := Checkpoint.new()
		cp.position = pos
		add_child(cp)


func _build_signs() -> void:
	for s in SIGNS:
		var sign_node := HintSign.new()
		sign_node.position = Vector2(s[0], s[1])
		sign_node.hint = s[2]
		sign_node.z_index = 1
		add_child(sign_node)


func _build_enemies() -> void:
	for e in ENEMIES:
		var sheep := RoboSheep.new()
		sheep.position = Vector2(e[0], e[1])
		sheep.size = e[2]
		sheep.max_hp = e[3]
		sheep.patrol_range = e[4]
		add_child(sheep)


func _build_story() -> void:
	var eule := HintSign.new()
	eule.tex = EULE_TEX
	eule.height = 210.0
	eule.position = Vector2(470, 770)
	eule.hint = "Bring Pip sicher nach Hause, Brummi! Und denk dran: Geh nie mit Fremden mit. Sammle unterwegs die goldenen Mut-Sterne!"
	add_child(eule)

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

	var eule_end := HintSign.new()
	eule_end.tex = EULE_TEX
	eule_end.height = 210.0
	eule_end.flip = true
	eule_end.position = Vector2(GOAL_X + 190.0, 770)
	eule_end.hint = "Oh Brummi, du warst so mutig! Komm mit Pip durch das Portal – wir gehen nach Hause."
	add_child(eule_end)

	_portal = Portal.new()
	_portal.position = Vector2(GOAL_X, 770)
	_portal.open = false
	_portal.reached.connect(_on_goal_reached)
	add_child(_portal)


func _build_player() -> void:
	_player = Brummi.new()
	_player.position = START
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--x="):
			_player.position = Vector2(arg.trim_prefix("--x=").to_float(), 300)
	_player.spawn_point = START
	_player.z_index = 2
	_player.health_changed.connect(func(hp: int) -> void: _hud.hp = hp)
	add_child(_player)
	_hud.player = _player

	var cam := Camera2D.new()
	cam.position = Vector2(0, -140)
	cam.limit_left = 0
	cam.limit_right = int(LEVEL_END)
	cam.limit_top = 0
	cam.limit_bottom = CAMERA_BOTTOM
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	_player.add_child(cam)


func _on_coin_collected() -> void:
	_collected += 1
	_hud.coins = _collected


func _on_rule_collected(text: String) -> void:
	_rule_index += 1
	_hud.stars = _rule_index
	_hud.show_message("Mut-Regel %d" % _rule_index, text, 6.0)


func _on_boss_defeated() -> void:
	_pip.free_pip()
	_portal.open = true
	Sound.sfx("fanfare")
	get_tree().create_timer(1.2).timeout.connect(func() -> void: Sound.sfx("portal_open"))
	_hud.show_message("Pip ist frei!", "Graupelz ist weggelaufen – gegen ein lautes NEIN hat er keine Chance. Bring Pip zu Oma Eule ins Portal!", 6.0)


func _on_goal_reached() -> void:
	Sound.sfx("goal")
	_player.controls_enabled = false
	_player.celebrating = true
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_hud, "fade", 1.0, 1.2)
	tw.tween_callback(func() -> void:
		Story.mode = "outro"
		get_tree().change_scene_to_file("res://scenes/story.tscn"))
