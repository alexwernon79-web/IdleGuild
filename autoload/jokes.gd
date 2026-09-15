extends Node
## Единая точка выдачи шуток. Весь текст лежит в data/jokes.json —
## чтобы добавить новые шутки, код трогать не нужно.

var _bank: Dictionary = {}


func _ready() -> void:
	_load_bank()


func _load_bank() -> void:
	var file := FileAccess.open("res://data/jokes.json", FileAccess.READ)
	if file == null:
		push_warning("Не удалось загрузить data/jokes.json — шутки закончились (и это не шутка)")
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		_bank = parsed
	else:
		push_warning("jokes.json повреждён — гильдия временно без чувства юмора")


func get_random(category: String, replacements: Dictionary = {}) -> String:
	var list: Array = _bank.get(category, [])
	if list.is_empty():
		return ""
	var text: String = list[randi() % list.size()]
	for key in replacements.keys():
		text = text.replace("{%s}" % key, str(replacements[key]))
	return text
