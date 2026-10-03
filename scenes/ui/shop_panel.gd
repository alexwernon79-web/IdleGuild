extends ScrollContainer

@onready var upgrade_list: VBoxContainer = $UpgradeList

var _rows: Dictionary = {}
var _sell_rows: Dictionary = {}
var _merchant_quip: Label

const CURRENCY_NAMES := {
	"gold": "золота",
	"wood": "дерева",
	"ore": "руды",
	"fish": "рыбы",
}

const RESOURCE_NAMES := {
	"wood": "Дерево",
	"ore": "Руда",
	"fish": "Рыба",
}


func _ready() -> void:
	_build_merchant_quip()
	_build_sell_section()
	_build_rows()
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.purchase_made.connect(_on_purchase_made)
	EventBus.resources_sold.connect(_on_resources_sold)
	visibility_changed.connect(_on_visibility_changed)


func _build_sell_section() -> void:
	upgrade_list.add_child(_make_header("Продажа ресурсов"))
	for resource_id in Balance.SELL_PRICES.keys():
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var icon := TextureRect.new()
		icon.texture = Icons.get_icon("resources", resource_id)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		var button := Button.new()
		button.pressed.connect(_on_sell_pressed.bind(resource_id))
		hbox.add_child(button)

		upgrade_list.add_child(row)
		_sell_rows[resource_id] = {"label": label, "button": button}
	upgrade_list.add_child(_make_header("Улучшения"))


func _make_header(text: String) -> Label:
	var header := Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 20)
	return header


func _on_sell_pressed(resource_id: String) -> void:
	GameState.sell_resource(resource_id)


func _on_resources_sold(_resource_id: String, _units: float, _earned: float) -> void:
	_merchant_quip.text = Jokes.get_random("sell")


func _refresh_sell_rows() -> void:
	for resource_id in _sell_rows.keys():
		var price: float = Balance.SELL_PRICES[resource_id]
		var units := floorf(GameState.resources.get(resource_id, 0.0))
		var res_name: String = RESOURCE_NAMES.get(resource_id, resource_id)
		_sell_rows[resource_id]["label"].text = "%s: %s (цена за шт.: %s)" % [res_name, NumberFormat.format(units), NumberFormat.format(price)]
		_sell_rows[resource_id]["button"].text = "Продать всё (+%s)" % NumberFormat.format(units * price)
		_sell_rows[resource_id]["button"].disabled = units < 1.0


func _build_merchant_quip() -> void:
	_merchant_quip = Label.new()
	_merchant_quip.autowrap_mode = TextServer.AUTOWRAP_WORD
	_merchant_quip.custom_minimum_size = Vector2(320, 0)
	_merchant_quip.modulate = Color(0.8, 0.8, 0.8, 1)
	upgrade_list.add_child(_merchant_quip)
	_refresh_merchant_quip()


func _refresh_merchant_quip() -> void:
	_merchant_quip.text = Jokes.get_random("item_flavor")


func _on_visibility_changed() -> void:
	if visible:
		_refresh_merchant_quip()


func _build_rows() -> void:
	for upgrade_id in GameState.upgrade_defs.keys():
		var def: UpgradeDef = GameState.upgrade_defs[upgrade_id]

		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		row.add_child(hbox)

		var icon := TextureRect.new()
		icon.texture = Icons.get_icon("upgrades", upgrade_id)
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon)

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
	_refresh_merchant_quip()


func _refresh_all() -> void:
	_refresh_sell_rows()
	for upgrade_id in _rows.keys():
		var def: UpgradeDef = GameState.upgrade_defs[upgrade_id]
		var level: int = GameState.upgrades_owned.get(upgrade_id, 0)
		var cost := Balance.upgrade_cost(def.base_cost, def.cost_growth, level)
		var currency_name: String = CURRENCY_NAMES.get(def.cost_currency, def.cost_currency)
		_rows[upgrade_id]["title"].text = "%s — %s %s" % [def.display_name, NumberFormat.format(cost), currency_name]
		_rows[upgrade_id]["button"].disabled = not GameState.can_afford_upgrade(upgrade_id)
