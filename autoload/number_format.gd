extends Node
## Форматирование больших чисел для UI (1200 -> "1.2K", 3400000 -> "3.4M").
## Нужно любому idle-игре — цифры быстро выходят за пределы читаемых.

const SUFFIXES := ["", "K", "M", "B", "T", "aa", "bb", "cc", "dd", "ee"]


func format(value: float, decimals: int = 1) -> String:
	var sign := ""
	if value < 0.0:
		sign = "-"
		value = abs(value)

	if value < 1000.0:
		return "%s%d" % [sign, int(value)]

	var magnitude := 0
	while value >= 1000.0 and magnitude < SUFFIXES.size() - 1:
		value /= 1000.0
		magnitude += 1

	# Округление может само перевалить за 1000 (например 999999 -> "1000.0K"),
	# в этом случае переносим в следующий разряд.
	var mult: float = pow(10.0, float(decimals))
	var rounded: float = round(value * mult) / mult
	if rounded >= 1000.0 and magnitude < SUFFIXES.size() - 1:
		rounded /= 1000.0
		magnitude += 1

	return "%s%s%s" % [sign, _trim_trailing_zeros(rounded, decimals), SUFFIXES[magnitude]]


func _trim_trailing_zeros(value: float, decimals: int) -> String:
	var text := "%.*f" % [decimals, value]
	if text.contains("."):
		while text.ends_with("0"):
			text = text.substr(0, text.length() - 1)
		if text.ends_with("."):
			text = text.substr(0, text.length() - 1)
	return text
