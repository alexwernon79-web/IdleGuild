class_name UpgradeDef
extends Resource
## Описание покупаемого апгрейда в магазине гильдии.

@export var id: String = ""
@export var display_name: String = ""
@export var flavor_text: String = ""
@export var base_cost: float = 10.0
@export var cost_currency: String = "gold"
@export var cost_growth: float = 1.15
@export var effect_target: String = "all"  # id активности или "all"
@export var effect_type: String = "multiplier"
@export var effect_value: float = 0.1
@export var max_level: int = 999
