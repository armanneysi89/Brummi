class_name RoboCrab
extends RoboSheep

## Graupelz' Robo-Krabbe am Hafen. Wird nach dem Besiegen fröhlich und läuft davon.


func _init() -> void:
	_tex_idle = preload("res://assets/enemy/crab_ref.png")
	_tex_walk = preload("res://assets/enemy/crab_walk.png")
	_tex_hit = preload("res://assets/enemy/crab_ref.png")
	_tex_happy = preload("res://assets/enemy/crab_happy.png")
