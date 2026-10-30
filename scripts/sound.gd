extends Node

## Zentrale Klangverwaltung: SFX-Stimmen, Musik mit Überblendung und Spannungs-Ebene (M schaltet die Musik stumm).

const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const MUSIC_PATH := "res://assets/audio/music/%s.ogg"
const SFX_VOICES := 14
const MUSIC_DB := -6.0
const SFX_DB := -5.0
const SILENT := -60.0
const COIN_STEPS := [0, 2, 4, 5, 7, 9, 11, 12]
## Diese Stücke laufen synchron mit einer stummen Spannungs-Ebene.
const PAIRED := {"level": "tension", "level2": "tension"}

var _sfx_cache := {}
var _voices: Array[AudioStreamPlayer] = []
var _layers := {}
var _tweens := {}
var _current := ""
var _tension_on := false
var _coin_combo := 0
var _coin_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)
	_make_bus("Music", MUSIC_DB)
	_make_bus("SFX", SFX_DB)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)


func _exit_tree() -> void:
	for p in _layers.values():
		p.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		var idx := AudioServer.get_bus_index("Music")
		AudioServer.set_bus_mute(idx, not AudioServer.is_bus_mute(idx))


func sfx(sound: String, volume_db := 0.0, pitch := 1.0, jitter := 0.04) -> void:
	var stream := _sfx_stream(sound)
	if stream == null:
		return
	var voice: AudioStreamPlayer = null
	for v in _voices:
		if not v.playing:
			voice = v
			break
	if voice == null:
		voice = _voices[0]
		_voices.push_back(_voices.pop_front())
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	voice.play()


## Münzen in kurzer Folge steigen als Tonleiter an.
func coin() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_coin_combo = _coin_combo + 1 if now - _coin_time < 0.9 else 0
	_coin_time = now
	sfx("coin", -2.0, pow(2.0, COIN_STEPS[mini(_coin_combo, COIN_STEPS.size() - 1)] / 12.0), 0.0)


func play_music(track: String, fade := 1.5) -> void:
	if track == _current:
		return
	_current = track
	_tension_on = false
	var keep: Array = [track]
	if PAIRED.has(track):
		keep.append(PAIRED[track])
	for n in _layers:
		if not n in keep:
			_fade(_layers[n], SILENT, fade, true)
	for n in keep:
		var p := _layer(n)
		if not p.playing:
			p.volume_db = SILENT
			p.play()
	_fade(_layer(track), 0.0, fade)
	if PAIRED.has(track):
		_fade(_layer(PAIRED[track]), SILENT, 0.1)


func stop_music(fade := 1.5) -> void:
	_current = ""
	for n in _layers:
		_fade(_layers[n], SILENT, fade, true)


## Blendet im Level die bedrohliche Ebene ein, solange Brummi gelockt wird.
func set_tension(on: bool) -> void:
	if on == _tension_on or not PAIRED.has(_current):
		return
	_tension_on = on
	_fade(_layer(_current), -14.0 if on else 0.0, 0.6)
	_fade(_layer(PAIRED[_current]), 0.0 if on else SILENT, 0.6)


func _sfx_stream(sound: String) -> AudioStream:
	if not _sfx_cache.has(sound):
		var path := SFX_PATH % sound
		_sfx_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	return _sfx_cache[sound]


func _layer(track: String) -> AudioStreamPlayer:
	if _layers.has(track):
		return _layers[track]
	var stream := load(MUSIC_PATH % track) as AudioStreamOggVorbis
	stream.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Music"
	p.volume_db = SILENT
	add_child(p)
	_layers[track] = p
	return p


func _fade(p: AudioStreamPlayer, to_db: float, time: float, stop_after := false) -> void:
	if _tweens.has(p) and _tweens[p].is_valid():
		_tweens[p].kill()
	var tw := create_tween()
	_tweens[p] = tw
	tw.tween_property(p, "volume_db", to_db, time)
	if stop_after:
		tw.tween_callback(p.stop)


func _make_bus(bus_name: String, db: float) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, db)
