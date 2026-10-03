extends Node
## Глобальная шина сигналов. Игровая логика и UI общаются через неё,
## а не напрямую, чтобы сцены не знали друг о друге.

signal resource_changed(resource_id: String, new_amount: float)
signal hero_leveled(hero_id: String, new_level: int)
signal purchase_made(upgrade_id: String, new_level: int)
signal resources_sold(resource_id: String, units: float, earned: float)
