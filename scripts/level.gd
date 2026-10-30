class_name Level
extends Node2D

## Gemeinsamer Aufbau aller Level. Die Level-Skripte füllen in _init() die Daten und überschreiben _build_story().

const EULE_TEX: Texture2D = preload("res://assets/characters/eule.png")

var level_end := 12400.0
var camera_bottom := 1200
var start := Vector2(260, 760)
var goal_x := 12150.0
var music := "level"
var title := ""
var subtitle := ""
var crate_tex: Texture2D = preload("res://assets/objects/crate.png")
# [Art, x, y (Oberkante), Breite, Bewegung]
var platforms := []
# [x, y, Text]
var rules := []
# [x, y (Fußpunkt), Text]
var signs := []
# [x, y (Fußpunkt), Größe, Leben, Patrouillenradius]
var enemies := []
var checkpoints := []
var crates := []
# Münzreihen: [x, y, Anzahl, Abstand]
var coin_rows := []
# [Art, x, y (Fußpunkt), Höhe, gespiegelt, z]
var decor := []

var _player: Brummi
var _hud: Hud
var _portal: Portal
var _monsters: Array[Graupelz] = []
var _collected := 0
var _rule_index := 0
var _was_lured := false


func _ready() -> void:
	Sound.play_music(music)
	var bg := Background.new()
	bg.level_width = level_end
	bg.camera_bottom = camera_bottom
	_theme_background(bg)
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


## Für Welt-spezifische Texturen überschreiben.
func _theme_background(_bg: Background) -> void:
	pass


func _theme_platform(_plat: Platform) -> void:
	pass


func _build_story() -> void:
	pass


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
	for p in platforms:
		var plat := Platform.new()
		plat.kind = p[0]
		plat.position = Vector2(p[1], p[2])
		plat.size = Vector2(p[3], 700)
		plat.move = p[4]
		_theme_platform(plat)
		add_child(plat)


func _build_walls() -> void:
	for x in [-30.0, level_end]:
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
	for d in decor:
		var node := Decor.new()
		node.kind = d[0]
		node.position = Vector2(d[1], d[2])
		node.height = d[3]
		node.flip = d[4]
		node.z_index = d[5]
		add_child(node)


func _build_crates() -> void:
	for pos in crates:
		var crate := StaticBody2D.new()
		crate.position = pos
		var shape := RectangleShape2D.new()
		shape.size = Vector2(88, 88)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(0, -44)
		crate.add_child(cs)
		var sp := Sprite2D.new()
		sp.texture = crate_tex
		var s := 92.0 / crate_tex.get_height()
		sp.scale = Vector2(s, s)
		sp.position = Vector2(0, -45)
		crate.add_child(sp)
		add_child(crate)


func _build_hud() -> void:
	_hud = Hud.new()
	_hud.level_width = level_end
	_hud.goal_x = goal_x
	_hud.total_stars = rules.size()
	_hud.title = title
	_hud.subtitle = subtitle
	for p in platforms:
		_hud.map_rects.append(Rect2(p[1], p[2], p[3], 0))
	add_child(_hud)


func _build_pickups() -> void:
	for row in coin_rows:
		for i in row[2]:
			var coin := Coin.new()
			coin.position = Vector2(row[0] + i * row[3], row[1])
			coin.collected.connect(_on_coin_collected)
			add_child(coin)
			_hud.total_coins += 1
	for r in rules:
		var star := RuleStar.new()
		star.position = Vector2(r[0], r[1])
		star.text = r[2]
		star.collected.connect(_on_rule_collected)
		add_child(star)
	for pos in checkpoints:
		var cp := Checkpoint.new()
		cp.position = pos
		add_child(cp)


func _build_signs() -> void:
	for s in signs:
		var sign_node := HintSign.new()
		sign_node.position = Vector2(s[0], s[1])
		sign_node.hint = s[2]
		sign_node.z_index = 1
		add_child(sign_node)


func _build_enemies() -> void:
	for e in enemies:
		var sheep := RoboSheep.new()
		sheep.position = Vector2(e[0], e[1])
		sheep.size = e[2]
		sheep.max_hp = e[3]
		sheep.patrol_range = e[4]
		add_child(sheep)


func _add_eule(pos: Vector2, hint: String, flip := false) -> HintSign:
	var eule := HintSign.new()
	eule.tex = EULE_TEX
	eule.height = 210.0
	eule.flip = flip
	eule.position = pos
	eule.hint = hint
	add_child(eule)
	return eule


func _build_player() -> void:
	_player = Brummi.new()
	_player.position = start
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--x="):
			_player.position = Vector2(arg.trim_prefix("--x=").to_float(), 300)
	_player.spawn_point = start
	_player.z_index = 2
	_player.health_changed.connect(func(hp: int) -> void: _hud.hp = hp)
	add_child(_player)
	_hud.player = _player

	var cam := Camera2D.new()
	cam.position = Vector2(0, -140)
	cam.limit_left = 0
	cam.limit_right = int(level_end)
	cam.limit_top = 0
	cam.limit_bottom = camera_bottom
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
