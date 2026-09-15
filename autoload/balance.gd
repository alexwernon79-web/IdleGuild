extends Node
## Все числовые формулы игры собраны здесь, чтобы баланс правился в одном месте.

const AUTOSAVE_INTERVAL_SECONDS := 60.0
const OFFLINE_CAP_SECONDS := 12.0 * 60.0 * 60.0  # 12 часов простоя — максимум, дальше гильдия сама не справится


func xp_to_next_level(level: int) -> float:
	return 10.0 * pow(float(level), 1.5)


func upgrade_cost(base_cost: float, growth: float, level_owned: int) -> float:
	return base_cost * pow(growth, level_owned)
