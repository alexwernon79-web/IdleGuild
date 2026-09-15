extends Node
## Сохранение/загрузка игры в JSON. Формат намеренно простой (id-шки, не ресурсы),
## чтобы не тянуть Resource-объекты через сериализацию.

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1


func load_or_init() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.new_game()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		GameState.new_game()
		return

	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("schema_version"):
		push_warning("Сейв повреждён — гильдия начинает с чистого листа (сейв сожрал дракон)")
		GameState.new_game()
		return

	_apply_save(parsed)


func _apply_save(data: Dictionary) -> void:
	GameState.resources = data.get("resources", {})
	GameState.upgrades_owned = data.get("upgrades_owned", {})
	GameState.heroes = data.get("heroes", [])
	if GameState.heroes.is_empty():
		GameState.new_game()
		return

	var saved_time: float = data.get("timestamp", Time.get_unix_time_from_system())
	var elapsed: float = Time.get_unix_time_from_system() - saved_time
	var gains := GameState.apply_offline_progress(elapsed)
	EventBus.offline_progress_ready.emit(gains, min(elapsed, Balance.OFFLINE_CAP_SECONDS))


func save_game() -> void:
	var data := {
		"schema_version": SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"resources": GameState.resources,
		"upgrades_owned": GameState.upgrades_owned,
		"heroes": GameState.heroes,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Не удалось сохранить игру")
		return
	file.store_string(JSON.stringify(data))
	file.close()
