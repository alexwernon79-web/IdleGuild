extends Control

const HeroCardScene := preload("res://scenes/hero/HeroCard.tscn")

@onready var tab_container: TabContainer = $Root/TabContainer
@onready var hero_list: VBoxContainer = $Root/TabContainer/HeroesTab/HeroList
@onready var offline_popup: Control = $OfflinePopup


func _ready() -> void:
	tab_container.set_tab_title(0, "Герои")
	tab_container.set_tab_title(1, "Магазин")
	_populate_heroes()
	EventBus.offline_progress_ready.connect(_on_offline_progress_ready)


func _populate_heroes() -> void:
	for hero in GameState.heroes:
		var card := HeroCardScene.instantiate()
		hero_list.add_child(card)
		card.setup(hero)


func _on_offline_progress_ready(gains: Dictionary, elapsed_seconds: float) -> void:
	if gains.is_empty():
		return
	offline_popup.show_summary(gains, elapsed_seconds)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game()
		get_tree().quit()
