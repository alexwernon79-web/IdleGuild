extends Control

@onready var summary_label: Label = $Center/PanelContainer/VBoxContainer/SummaryLabel
@onready var joke_label: Label = $Center/PanelContainer/VBoxContainer/JokeLabel
@onready var close_button: Button = $Center/PanelContainer/VBoxContainer/CloseButton

const CURRENCY_NAMES := {
	"gold": "золота",
	"wood": "дерева",
	"ore": "руды",
	"fish": "рыбы",
	"laziness_xp": "опыта лени",
}


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)


func show_summary(gains: Dictionary, elapsed_seconds: float) -> void:
	var parts: Array[String] = []
	for resource_id in gains.keys():
		var currency_name: String = CURRENCY_NAMES.get(resource_id, resource_id)
		parts.append("%d %s" % [int(gains[resource_id]), currency_name])
	var hours := int(elapsed_seconds / 3600.0)
	var minutes := int(fmod(elapsed_seconds, 3600.0) / 60.0)
	summary_label.text = "Вы отсутствовали %d ч %d мин. Гильдия заработала: %s." % [hours, minutes, ", ".join(parts)]
	joke_label.text = Jokes.get_random("offline_return")
	visible = true
