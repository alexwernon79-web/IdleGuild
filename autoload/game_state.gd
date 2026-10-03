extends Node
## Центральное состояние игры: ресурсы, герои, апгрейды и тик простоя.

var resources: Dictionary = {
	"gold": 0.0,
	"wood": 0.0,
	"ore": 0.0,
	"fish": 0.0,
	"laziness_xp": 0.0,
}

var hero_classes: Dictionary = {}   # id -> HeroClassDef
var activities: Dictionary = {}     # id -> ActivityDef
var upgrade_defs: Dictionary = {}   # id -> UpgradeDef

var heroes: Array = []              # [{id, class_id, level, xp, activity_id}, ...]
var upgrades_owned: Dictionary = {} # upgrade_id -> level (int)

var offline_report: Dictionary = {} # {gains, elapsed_seconds}; Main показывает его при старте

var _autosave_timer: Timer


func _ready() -> void:
	_load_definitions()
	SaveManager.load_or_init()
	_start_autosave()


func _load_definitions() -> void:
	_load_dir("res://resources/heroes", hero_classes)
	_load_dir("res://resources/activities", activities)
	_load_dir("res://resources/upgrades", upgrade_defs)


func _load_dir(path: String, into: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Не удалось открыть папку ресурсов: %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res = load(path + "/" + file_name)
			if res != null:
				into[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func new_game() -> void:
	resources = {"gold": 0.0, "wood": 0.0, "ore": 0.0, "fish": 0.0, "laziness_xp": 0.0}
	upgrades_owned = {}
	heroes = []
	var starter_activities := ["chop_wood", "mine_ore", "fish"]
	var i := 0
	for class_id in hero_classes.keys():
		heroes.append({
			"id": "hero_%d" % i,
			"class_id": class_id,
			"level": 1,
			"xp": 0.0,
			"activity_id": starter_activities[i % starter_activities.size()],
		})
		i += 1


func _start_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = Balance.AUTOSAVE_INTERVAL_SECONDS
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(SaveManager.save_game)
	add_child(_autosave_timer)


func _process(delta: float) -> void:
	for hero in heroes:
		_advance_hero(hero, delta)


func _advance_hero(hero: Dictionary, delta: float) -> void:
	var activity: ActivityDef = activities.get(hero["activity_id"])
	if activity == null:
		return
	var hero_class: HeroClassDef = hero_classes.get(hero["class_id"])
	var class_mult: float = 1.0
	if hero_class and hero_class.base_rates.has(activity.id):
		class_mult = hero_class.base_rates[activity.id]
	var upgrade_mult := get_upgrade_multiplier(activity.id)
	var produced := activity.base_rate * class_mult * upgrade_mult * delta
	add_resource(activity.resource_id, produced)
	_add_xp(hero, activity.xp_rate * delta)


func get_upgrade_multiplier(target_id: String) -> float:
	var mult := 1.0
	for upgrade_id in upgrades_owned.keys():
		var def: UpgradeDef = upgrade_defs.get(upgrade_id)
		if def == null:
			continue
		if def.effect_target == target_id or def.effect_target == "all":
			var level: int = upgrades_owned[upgrade_id]
			mult *= (1.0 + def.effect_value * level)
	return mult


func add_resource(resource_id: String, amount: float) -> void:
	resources[resource_id] = resources.get(resource_id, 0.0) + amount
	EventBus.resource_changed.emit(resource_id, resources[resource_id])


func _add_xp(hero: Dictionary, amount: float) -> void:
	hero["xp"] += amount
	var needed := Balance.xp_to_next_level(hero["level"])
	while hero["xp"] >= needed:
		hero["xp"] -= needed
		hero["level"] += 1
		EventBus.hero_leveled.emit(hero["id"], hero["level"])
		needed = Balance.xp_to_next_level(hero["level"])


func set_hero_activity(hero_id: String, activity_id: String) -> void:
	for hero in heroes:
		if hero["id"] == hero_id:
			hero["activity_id"] = activity_id
			return


func get_hero_class(hero: Dictionary) -> HeroClassDef:
	return hero_classes.get(hero["class_id"])


func can_afford_upgrade(upgrade_id: String) -> bool:
	var def: UpgradeDef = upgrade_defs.get(upgrade_id)
	if def == null:
		return false
	var level: int = upgrades_owned.get(upgrade_id, 0)
	if level >= def.max_level:
		return false
	var cost := Balance.upgrade_cost(def.base_cost, def.cost_growth, level)
	return resources.get(def.cost_currency, 0.0) >= cost


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_afford_upgrade(upgrade_id):
		return false
	var def: UpgradeDef = upgrade_defs[upgrade_id]
	var level: int = upgrades_owned.get(upgrade_id, 0)
	var cost := Balance.upgrade_cost(def.base_cost, def.cost_growth, level)
	resources[def.cost_currency] -= cost
	upgrades_owned[upgrade_id] = level + 1
	EventBus.resource_changed.emit(def.cost_currency, resources[def.cost_currency])
	EventBus.purchase_made.emit(upgrade_id, level + 1)
	return true


func apply_offline_progress(elapsed_seconds: float) -> Dictionary:
	var capped: float = min(elapsed_seconds, Balance.OFFLINE_CAP_SECONDS)
	if capped <= 0.0:
		return {}
	var gains: Dictionary = {}
	for hero in heroes:
		var activity: ActivityDef = activities.get(hero["activity_id"])
		if activity == null:
			continue
		var hero_class: HeroClassDef = hero_classes.get(hero["class_id"])
		var class_mult: float = 1.0
		if hero_class and hero_class.base_rates.has(activity.id):
			class_mult = hero_class.base_rates[activity.id]
		var upgrade_mult := get_upgrade_multiplier(activity.id)
		var produced := activity.base_rate * class_mult * upgrade_mult * capped
		add_resource(activity.resource_id, produced)
		gains[activity.resource_id] = gains.get(activity.resource_id, 0.0) + produced
		_add_xp(hero, activity.xp_rate * capped)
	return gains
