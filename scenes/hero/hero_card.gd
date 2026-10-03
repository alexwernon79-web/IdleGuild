extends PanelContainer

@onready var avatar: TextureRect = $HBoxContainer/Avatar
@onready var name_label: Label = $HBoxContainer/Info/NameLabel
@onready var desc_label: Label = $HBoxContainer/Info/DescLabel
@onready var xp_bar: ProgressBar = $HBoxContainer/Info/XpBar
@onready var activity_flavor: Label = $HBoxContainer/Info/ActivityFlavor
@onready var activity_select: OptionButton = $HBoxContainer/Info/ActivitySelect

var _hero_id: String = ""


func setup(hero: Dictionary) -> void:
	_hero_id = hero["id"]
	var hero_class: HeroClassDef = GameState.get_hero_class(hero)
	if hero_class:
		avatar.texture = Icons.get_icon("heroes", hero_class.id)
		desc_label.text = hero_class.description
	_populate_activities(hero["activity_id"])
	_refresh_flavor(hero["activity_id"])


func _populate_activities(current_activity_id: String) -> void:
	activity_select.add_theme_constant_override("icon_max_width", 24)
	activity_select.get_popup().add_theme_constant_override("icon_max_width", 24)
	activity_select.clear()
	var idx := 0
	var selected_idx := 0
	for activity_id in GameState.activities.keys():
		var activity: ActivityDef = GameState.activities[activity_id]
		activity_select.add_icon_item(Icons.get_icon("activities", activity_id), activity.display_name, idx)
		activity_select.set_item_metadata(idx, activity_id)
		if activity_id == current_activity_id:
			selected_idx = idx
		idx += 1
	activity_select.select(selected_idx)
	if not activity_select.item_selected.is_connected(_on_activity_selected):
		activity_select.item_selected.connect(_on_activity_selected)


func _on_activity_selected(index: int) -> void:
	var activity_id: String = activity_select.get_item_metadata(index)
	GameState.set_hero_activity(_hero_id, activity_id)
	_refresh_flavor(activity_id)


func _refresh_flavor(activity_id: String) -> void:
	var activity: ActivityDef = GameState.activities.get(activity_id)
	activity_flavor.text = activity.flavor_text if activity else ""


func _process(_delta: float) -> void:
	var hero := _find_hero()
	if hero.is_empty():
		return
	var hero_class: HeroClassDef = GameState.get_hero_class(hero)
	if hero_class:
		name_label.text = "%s (ур. %d)" % [hero_class.display_name, int(hero["level"])]
	var needed := Balance.xp_to_next_level(int(hero["level"]))
	xp_bar.max_value = needed
	xp_bar.value = hero["xp"]


func _find_hero() -> Dictionary:
	for hero in GameState.heroes:
		if hero["id"] == _hero_id:
			return hero
	return {}
