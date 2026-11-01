extends Node

## Speichert den Spielstand: Welche Levels sind freigeschaltet?
## Level 1 ist immer frei, Level 2 wird mit dem Abschluss von Level 1 freigeschaltet.

const SAVE_PATH := "user://progress.save"
const MAX_LEVEL := 2

var unlocked := 1


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	unlocked = 1
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			unlocked = clampi(f.get_line().to_int(), 1, MAX_LEVEL)


func save_progress() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_line(str(unlocked))


func is_unlocked(level: int) -> bool:
	return level <= unlocked


func complete(level: int) -> void:
	unlocked = maxi(unlocked, level + 1)
	save_progress()
