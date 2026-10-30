extends Node

# Autoload: progresso do jogador, configuracoes de audio/video e salvamento.

const SAVE_PATH := "user://prisma_save.cfg"
const LevelData := preload("res://scripts/levels.gd")
const Geometria = preload("res://scripts/geometria.gd")

var levels: Array = []
var unlocked_level := 0
var stars: Array = []
var best_rotations: Array = []
var current_level := 0

# Pausa automatica ao trocar de janela (o teste automatico desliga).
var autopause := true

var music_volume := 0.7
var sfx_volume := 0.8
var music_enabled := true
# Guia de angulos e explicacoes (parte educativa). Tecla G liga/desliga.
var show_angles := true
var fullscreen := false

# true quando o jogador esta usando teclado/controle nos menus (mostra o destaque de foco).
var last_input_pad := false
var _focus_ring: StyleBoxFlat
var _no_focus := StyleBoxEmpty.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	levels = LevelData.get_levels()
	_ensure_audio_buses()
	_reset_progress_arrays()
	load_data()
	apply_settings()
	_build_focus_ring()
	_apply_focus_style()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var toggle_fullscreen: bool = event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed)
		if toggle_fullscreen:
			set_fullscreen(not fullscreen)
			get_viewport().set_input_as_handled()
			return

	_track_input_device(event)

	# Primeira seta/Tab num menu sem foco: foca o botao principal da tela.
	var navigation := event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
		or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") \
		or event.is_action_pressed("ui_focus_next")
	if navigation and get_viewport().gui_get_focus_owner() == null:
		if focus_default():
			get_viewport().set_input_as_handled()


# Foca o controle padrao visivel (grupo "default_focus"). Retorna true se conseguiu.
func focus_default() -> bool:
	for node in get_tree().get_nodes_in_group("default_focus"):
		var control := node as Control
		if control != null and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
			control.grab_focus()
			return true
	return false


func _track_input_device(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed():
			_set_pad_mode(true)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) > 0.5:
			_set_pad_mode(true)
	elif event is InputEventMouseButton:
		_set_pad_mode(false)
	elif event is InputEventMouseMotion:
		if event.relative.length() > 3.0:
			_set_pad_mode(false)


func _set_pad_mode(value: bool) -> void:
	if value == last_input_pad:
		return
	last_input_pad = value
	_apply_focus_style()


func _build_focus_ring() -> void:
	_focus_ring = StyleBoxFlat.new()
	_focus_ring.draw_center = false
	_focus_ring.set_border_width_all(2)
	_focus_ring.border_color = Color(1.0, 0.86, 0.36)
	_focus_ring.set_corner_radius_all(9)
	_focus_ring.set_expand_margin_all(3.0)
	_focus_ring.anti_aliasing = true


func _apply_focus_style() -> void:
	# Com mouse o destaque de foco fica invisivel; com teclado/controle aparece.
	var theme := ThemeDB.get_project_theme()
	if theme == null or _focus_ring == null:
		return
	for type_name in ["Button", "CheckButton", "HSlider"]:
		theme.set_stylebox("focus", type_name, _focus_ring if last_input_pad else _no_focus)


# ---------------------------------------------------------------- progresso

func level_count() -> int:
	return levels.size()


func is_unlocked(index: int) -> bool:
	return index <= unlocked_level


func stars_for(index: int, rotations: int) -> int:
	# Regra das estrelas isolada e testada em Geometria.
	return Geometria.estrelas_por_rotacoes(rotations, int(levels[index]["par"]))


func record_result(index: int, rotations: int) -> Dictionary:
	var earned := stars_for(index, rotations)
	var previous_best: int = best_rotations[index]
	var is_record := previous_best < 0 or rotations < previous_best
	var first_clear: bool = stars[index] == 0

	stars[index] = maxi(stars[index], earned)
	if is_record:
		best_rotations[index] = rotations
	unlocked_level = clampi(maxi(unlocked_level, index + 1), 0, levels.size() - 1)
	save_data()

	return {"stars": earned, "record": is_record and previous_best >= 0, "first_clear": first_clear}


func total_stars() -> int:
	var total := 0
	for value in stars:
		total += int(value)
	return total


func completed_levels() -> int:
	var total := 0
	for value in stars:
		if int(value) > 0:
			total += 1
	return total


func reset_progress() -> void:
	_reset_progress_arrays()
	unlocked_level = 0
	save_data()


func _reset_progress_arrays() -> void:
	stars.clear()
	best_rotations.clear()
	for _index in range(levels.size()):
		stars.append(0)
		best_rotations.append(-1)


# ---------------------------------------------------------------- audio/video

func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func apply_settings() -> void:
	_apply_bus("Music", music_volume, not music_enabled)
	_apply_bus("SFX", sfx_volume, false)
	_apply_window_mode()


func _apply_bus(bus_name: String, volume: float, force_mute: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, force_mute or volume <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_data()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_settings()
	save_data()


func toggle_music() -> bool:
	music_enabled = not music_enabled
	apply_settings()
	save_data()
	return music_enabled


func set_show_angles(value: bool) -> void:
	show_angles = value
	save_data()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window_mode()
	save_data()


func _apply_window_mode() -> void:
	# O modo de janela so pode ser trocado fora do editor embutido.
	if DisplayServer.get_name() == "headless":
		return
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fullscreen == fullscreen:
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ---------------------------------------------------------------- arquivo

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_level", unlocked_level)
	config.set_value("progress", "stars", stars)
	config.set_value("progress", "best_rotations", best_rotations)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "music_enabled", music_enabled)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "show_angles", show_angles)
	config.save(SAVE_PATH)


func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	unlocked_level = clampi(int(config.get_value("progress", "unlocked_level", 0)), 0, levels.size() - 1)
	_copy_into(stars, config.get_value("progress", "stars", []), 0)
	_copy_into(best_rotations, config.get_value("progress", "best_rotations", []), -1)
	music_volume = float(config.get_value("settings", "music_volume", music_volume))
	sfx_volume = float(config.get_value("settings", "sfx_volume", sfx_volume))
	music_enabled = bool(config.get_value("settings", "music_enabled", music_enabled))
	fullscreen = bool(config.get_value("settings", "fullscreen", fullscreen))
	show_angles = bool(config.get_value("settings", "show_angles", show_angles))


func _copy_into(target: Array, source, fallback: int) -> void:
	# Mantem o tamanho atual mesmo se o save for de uma versao com menos fases.
	for index in range(target.size()):
		if source is Array and index < source.size():
			target[index] = int(source[index])
		else:
			target[index] = fallback
