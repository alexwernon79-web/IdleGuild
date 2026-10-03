extends Node
## Поиск иконок по соглашению: res://assets/icons/<группа>/<id>.svg
## Группы: heroes, resources, activities, upgrades. Нет файла — возвращаем null.

const ICON_DIR := "res://assets/icons/"

var _cache: Dictionary = {}


func get_icon(group: String, id: String) -> Texture2D:
	var path := "%s%s/%s.svg" % [ICON_DIR, group, id]
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
