extends Node
## Пользовательские настройки (хранятся отдельно от сейва, чтобы сброс прогресса их не трогал).

const SETTINGS_PATH := "user://settings.cfg"

var volume_percent: float = 80.0


func _ready() -> void:
	_load()
	_apply_volume()


func set_volume_percent(value: float) -> void:
	volume_percent = clampf(value, 0.0, 100.0)
	_apply_volume()
	_save()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume_percent / 100.0))
	AudioServer.set_bus_mute(bus, volume_percent <= 0.0)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	volume_percent = clampf(config.get_value("audio", "volume_percent", volume_percent), 0.0, 100.0)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume_percent", volume_percent)
	config.save(SETTINGS_PATH)
