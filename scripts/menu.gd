extends Node2D

@onready var music_player: AudioStreamPlayer = $MenuMusic
@onready var main_panel: Control = $HUD/MainPanel
@onready var options_panel: Control = $HUD/OptionsPanel
@onready var volume_slider: HSlider = $HUD/OptionsPanel/VBox/VolumeSlider
@onready var volume_value_label: Label = $HUD/OptionsPanel/VBox/VolumeValueLabel
@onready var mute_button: Button = $HUD/OptionsPanel/VBox/MuteButton

var is_muted = false


func _ready() -> void:
	_setup_music()
	_show_main_menu()
	volume_slider.value = 70.0
	_apply_volume(volume_slider.value)


func _setup_music() -> void:
	if music_player.stream != null:
		_set_loop_if_available(music_player.stream)

	music_player.play()


func _set_loop_if_available(audio_stream: Resource) -> void:
	for property in audio_stream.get_property_list():
		if property["name"] == "loop":
			audio_stream.set("loop", true)
		elif property["name"] == "loop_mode":
			audio_stream.set("loop_mode", 1)


func _show_main_menu() -> void:
	main_panel.visible = true
	options_panel.visible = false


func _show_options() -> void:
	main_panel.visible = false
	options_panel.visible = true


func _apply_volume(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	var normalized = clamp(value / 100.0, 0.0, 1.0)

	if normalized <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(normalized))

	volume_value_label.text = "Volume: %d%%" % int(value)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_options_button_pressed() -> void:
	_show_options()


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	_show_main_menu()


func _on_volume_slider_value_changed(value: float) -> void:
	is_muted = value <= 0.0
	_apply_volume(value)
	mute_button.text = "Som: desligado" if is_muted else "Som: ligado"


func _on_mute_button_pressed() -> void:
	is_muted = not is_muted

	if is_muted:
		volume_slider.value = 0.0
	else:
		volume_slider.value = 70.0

	mute_button.text = "Som: desligado" if is_muted else "Som: ligado"
