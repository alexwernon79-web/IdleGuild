extends VBoxContainer

@onready var gold_label: Label = $ResourceRow/GoldLabel
@onready var wood_label: Label = $ResourceRow/WoodLabel
@onready var ore_label: Label = $ResourceRow/OreLabel
@onready var fish_label: Label = $ResourceRow/FishLabel
@onready var lazy_label: Label = $ResourceRow/LazyLabel
@onready var toast_label: Label = $ToastLabel
@onready var toast_timer: Timer = $ToastTimer


func _ready() -> void:
	$ResourceRow/GoldIcon.texture = Icons.get_icon("resources", "gold")
	$ResourceRow/WoodIcon.texture = Icons.get_icon("resources", "wood")
	$ResourceRow/OreIcon.texture = Icons.get_icon("resources", "ore")
	$ResourceRow/FishIcon.texture = Icons.get_icon("resources", "fish")
	$ResourceRow/LazyIcon.texture = Icons.get_icon("resources", "laziness_xp")
	_refresh_all()
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.hero_leveled.connect(_on_hero_leveled)
	EventBus.purchase_made.connect(_on_purchase_made)
	toast_timer.timeout.connect(_show_random_quip)
	toast_timer.start()
	toast_label.text = ""


func _refresh_all() -> void:
	for resource_id in GameState.resources.keys():
		_on_resource_changed(resource_id, GameState.resources[resource_id])


func _on_resource_changed(resource_id: String, new_amount: float) -> void:
	var text := NumberFormat.format(new_amount)
	match resource_id:
		"gold":
			gold_label.text = "Золото: %s" % text
		"wood":
			wood_label.text = "Дерево: %s" % text
		"ore":
			ore_label.text = "Руда: %s" % text
		"fish":
			fish_label.text = "Рыба: %s" % text
		"laziness_xp":
			lazy_label.text = "Опыт лени: %s" % text


func _on_hero_leveled(hero_id: String, new_level: int) -> void:
	toast_label.text = Jokes.get_random("level_up", {"hero": _hero_display_name(hero_id), "level": str(new_level)})


func _on_purchase_made(upgrade_id: String, new_level: int) -> void:
	toast_label.text = Jokes.get_random("purchase", {"level": str(new_level)})


func _show_random_quip() -> void:
	if GameState.heroes.is_empty():
		return
	var hero: Dictionary = GameState.heroes[randi() % GameState.heroes.size()]
	var hero_class: HeroClassDef = GameState.get_hero_class(hero)
	var hero_name := hero_class.display_name if hero_class else "Герой"
	toast_label.text = Jokes.get_random("idle_quips", {"hero": hero_name})


func _hero_display_name(hero_id: String) -> String:
	for hero in GameState.heroes:
		if hero["id"] == hero_id:
			var hero_class: HeroClassDef = GameState.get_hero_class(hero)
			return hero_class.display_name if hero_class else hero_id
	return hero_id
