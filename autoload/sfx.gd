extends Node
## Звуковые эффекты. Слушает сигналы EventBus и сам вешает «клик» на любые кнопки и вкладки.
## Файлы генерирует tools/generate_sfx.py.

const SOUNDS := {
	"click": "res://assets/audio/sfx/click.wav",
	"sell": "res://assets/audio/sfx/sell.wav",
	"purchase": "res://assets/audio/sfx/purchase.wav",
	"level_up": "res://assets/audio/sfx/level_up.wav",
}
const MIN_GAP_MS := 60  # защита от залпа одинаковых звуков в один кадр

var _players: Dictionary = {}
var _last_played_ms: Dictionary = {}


func _ready() -> void:
	for sound_name in SOUNDS.keys():
		var path: String = SOUNDS[sound_name]
		if not ResourceLoader.exists(path):
			continue
		var player := AudioStreamPlayer.new()
		player.stream = load(path)
		player.max_polyphony = 4
		add_child(player)
		_players[sound_name] = player

	EventBus.purchase_made.connect(_on_purchase_made)
	EventBus.resources_sold.connect(_on_resources_sold)
	EventBus.hero_leveled.connect(_on_hero_leveled)
	get_tree().node_added.connect(_on_node_added)


func play(sound_name: String) -> void:
	var player: AudioStreamPlayer = _players.get(sound_name)
	if player == null:
		return
	var now := Time.get_ticks_msec()
	if now - _last_played_ms.get(sound_name, -MIN_GAP_MS) < MIN_GAP_MS:
		return
	_last_played_ms[sound_name] = now
	player.play()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind("click"))
	elif node is TabContainer:
		node.tab_changed.connect(_on_tab_changed)


func _on_tab_changed(_tab: int) -> void:
	play("click")


func _on_purchase_made(_upgrade_id: String, _new_level: int) -> void:
	play("purchase")


func _on_resources_sold(_resource_id: String, _units: float, _earned: float) -> void:
	play("sell")


func _on_hero_leveled(_hero_id: String, _new_level: int) -> void:
	play("level_up")
