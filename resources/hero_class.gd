class_name HeroClassDef
extends Resource
## Описание класса героя. base_rates — множитель к базовой скорости
## каждой активности (по id), 1.0 = нейтрально.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var base_rates: Dictionary = {}
@export var color: Color = Color.WHITE
