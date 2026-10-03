extends Control

const SPLASH_SECONDS := 10.0
const FADE_SECONDS := 1.0
const MAIN_SCENE := "res://scenes/main/Main.tscn"

@onready var content: Control = $Center


func _ready() -> void:
	content.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_interval(SPLASH_SECONDS - FADE_SECONDS * 2.0)
	tween.tween_property(content, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(get_tree().change_scene_to_file.bind(MAIN_SCENE))
