extends ScrollContainer

@onready var upgrade_list: VBoxContainer = $UpgradeList

var _rows: Dictionary = {}

const CURRENCY_NAMES := {
	"gold": "золота",
	"wood": "дерева",
	"ore": "руды",
	"fish": "рыбы",
}


func _ready() -> void:
	_build_rows()
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.purchase_made.connect(_on_purchase_made)


func _build_rows() -> void:
	for upgrade_id in GameState.upgrade_defs.keys():
		var def: UpgradeDef = GameState.upgrade_defs[upgrade_id]

		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		var flavor := Label.new()
		flavor.text = def.flavor_text
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD
		flavor.custom_minimum_size = Vector2(320, 0)
		var level_label := Label.new()
		level_label.text = "Уровень: %d" % GameState.upgrades_owned.get(upgrade_id, 0)
		info.add_child(title)
		info.add_child(flavor)
		info.add_child(level_label)
		hbox.add_child(info)

		var buy_button := Button.new()
		buy_button.text = "Купить"
		buy_button.pressed.connect(_on_buy_pressed.bind(upgrade_id))
		hbox.add_child(buy_button)

		upgrade_list.add_child(row)
		_rows[upgrade_id] = {"title": title, "button": buy_button, "level_label": level_label}
	_refresh_all()


func _on_buy_pressed(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)


func _on_resource_changed(_resource_id: String, _new_amount: float) -> void:
	_refresh_all()


func _on_purchase_made(upgrade_id: String, new_level: int) -> void:
	if _rows.has(upgrade_id):
		_rows[upgrade_id]["level_label"].text = "Уровень: %d" % new_level


func _refresh_all() -> void:
	for upgrade_id in _rows.keys():
		var def: UpgradeDef = GameState.upgrade_defs[upgrade_id]
		var level: int = GameState.upgrades_owned.get(upgrade_id, 0)
		var cost := Balance.upgrade_cost(def.base_cost, def.cost_growth, level)
		var currency_name: String = CURRENCY_NAMES.get(def.cost_currency, def.cost_currency)
		_rows[upgrade_id]["title"].text = "%s — %s %s" % [def.display_name, NumberFormat.format(cost), currency_name]
		_rows[upgrade_id]["button"].disabled = not GameState.can_afford_upgrade(upgrade_id)
