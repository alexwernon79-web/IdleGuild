extends VBoxContainer

@onready var volume_slider: HSlider = $VolumeRow/VolumeSlider
@onready var volume_value: Label = $VolumeRow/VolumeValue
@onready var reset_button: Button = $ResetButton
@onready var version_label: Label = $VersionLabel
@onready var reset_dialog: ConfirmationDialog = $ResetDialog


func _ready() -> void:
	volume_slider.value = Settings.volume_percent
	_update_volume_label(Settings.volume_percent)
	volume_slider.value_changed.connect(_on_volume_changed)
	reset_button.pressed.connect(reset_dialog.popup_centered)
	reset_dialog.confirmed.connect(_on_reset_confirmed)
	version_label.text = "Версия игры: %s" % ProjectSettings.get_setting("application/config/version", "0.0.0")


func _on_volume_changed(value: float) -> void:
	Settings.set_volume_percent(value)
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % int(value)


func _on_reset_confirmed() -> void:
	GameState.new_game()
	GameState.offline_report = {}
	SaveManager.save_game()
	get_tree().reload_current_scene()
