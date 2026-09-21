extends Node2D

@onready var emitter = $Puzzle/Emitter
@onready var beam = $Puzzle/LightBeam
@onready var crystal = $Puzzle/Crystal
@onready var music_player = $MusicPlayer
@onready var mirrors = [
	$Puzzle/Mirrors/MirrorA,
	$Puzzle/Mirrors/MirrorB,
	$Puzzle/Mirrors/MirrorC,
	$Puzzle/Mirrors/MirrorD,
]
@onready var obstacles = [
	$Puzzle/Obstacles/ObstacleA,
	$Puzzle/Obstacles/ObstacleB,
]
@onready var level_label: Label = $HUD/Panel/VBox/LevelLabel
@onready var objective_label: Label = $HUD/Panel/VBox/ObjectiveLabel
@onready var movement_label: Label = $HUD/Panel/VBox/MovementLabel
@onready var state_label: Label = $HUD/Panel/VBox/StateLabel
@onready var feedback_label: Label = $HUD/Panel/VBox/FeedbackLabel
@onready var progress_label: Label = $HUD/SidePanel/VBox/ProgressLabel
@onready var music_status_label: Label = $HUD/SidePanel/VBox/MusicStatusLabel
@onready var completion_shade: ColorRect = $HUD/CompletionShade
@onready var victory_label: Label = $HUD/VictoryLabel
@onready var victory_hint_label: Label = $HUD/VictoryHintLabel

var selected_mirror = null
var rotation_count = 0
var completed = false
var current_level = 0
var completion_tween = null

var levels = [
	{
		"name": "Fase 1 - Reflexao basica",
		"objective": "Leve a luz ate o cristal usando 2 espelhos.",
		"emitter_position": Vector2(120, 360),
		"emitter_rotation": 0.0,
		"crystal_position": Vector2(780, 560),
		"mirrors": [
			{"active": true, "position": Vector2(420, 360), "rotation": 45.0, "can_rotate": true},
			{"active": true, "position": Vector2(420, 560), "rotation": -45.0, "can_rotate": true},
			{"active": false, "position": Vector2(0, 0), "rotation": 0.0, "can_rotate": true},
			{"active": false, "position": Vector2(0, 0), "rotation": 0.0, "can_rotate": true},
		],
		"obstacles": [
			{"active": false, "position": Vector2(0, 0), "size": Vector2(80, 180)},
			{"active": false, "position": Vector2(0, 0), "size": Vector2(80, 180)},
		],
	},
	{
		"name": "Fase 2 - Desvio com obstaculo",
		"objective": "Use os 3 espelhos para contornar o bloco vermelho.",
		"emitter_position": Vector2(120, 250),
		"emitter_rotation": 0.0,
		"crystal_position": Vector2(760, 250),
		"mirrors": [
			{"active": true, "position": Vector2(360, 250), "rotation": 30.0, "can_rotate": true},
			{"active": true, "position": Vector2(360, 520), "rotation": 60.0, "can_rotate": true},
			{"active": true, "position": Vector2(760, 520), "rotation": -30.0, "can_rotate": true},
			{"active": false, "position": Vector2(0, 0), "rotation": 0.0, "can_rotate": true},
		],
		"obstacles": [
			{"active": true, "position": Vector2(560, 250), "size": Vector2(95, 210)},
			{"active": false, "position": Vector2(0, 0), "size": Vector2(80, 180)},
		],
	},
	{
		"name": "Fase 3 - Espelho fixo e simetria",
		"objective": "Monte um caminho em escada e use o espelho azul fixo.",
		"emitter_position": Vector2(120, 560),
		"emitter_rotation": 0.0,
		"crystal_position": Vector2(1000, 500),
		"mirrors": [
			{"active": true, "position": Vector2(340, 560), "rotation": -30.0, "can_rotate": true},
			{"active": true, "position": Vector2(340, 300), "rotation": -60.0, "can_rotate": true},
			{"active": true, "position": Vector2(760, 300), "rotation": 45.0, "can_rotate": false},
			{"active": true, "position": Vector2(760, 500), "rotation": 30.0, "can_rotate": true},
		],
		"obstacles": [
			{"active": true, "position": Vector2(560, 560), "size": Vector2(95, 150)},
			{"active": true, "position": Vector2(560, 420), "size": Vector2(120, 80)},
		],
	},
]


func _ready() -> void:
	for mirror in mirrors:
		mirror.selected.connect(_on_mirror_selected)
		mirror.rotated.connect(_on_mirror_rotated)

	beam.crystal_activated.connect(_on_crystal_activated)
	_load_level(0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_mirror_at_mouse()
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return

	if event.keycode == KEY_R:
		_load_level(current_level)
		return

	if event.keycode == KEY_M:
		music_player.toggle_music()
		_update_hud()
		return

	if event.keycode == KEY_N and completed:
		if current_level == levels.size() - 1:
			_show_game_complete()
		else:
			_load_level(current_level + 1)
		return

	if event.keycode == KEY_TAB:
		_select_next_mirror()
		return

	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		var mirror_index = event.keycode - KEY_1
		if mirror_index < mirrors.size():
			_on_mirror_selected(mirrors[mirror_index])
		return

	if completed or selected_mirror == null:
		return

	if event.keycode == KEY_Q:
		_rotate_selected_mirror(-1)
	elif event.keycode == KEY_E:
		_rotate_selected_mirror(1)


func _load_level(level_index: int) -> void:
	current_level = level_index
	completed = false
	rotation_count = 0
	selected_mirror = null
	_hide_completion_animation()

	var level = levels[current_level]
	emitter.position = level["emitter_position"]
	emitter.rotation_degrees = level["emitter_rotation"]
	crystal.position = level["crystal_position"]
	crystal.reset_crystal()

	for index in range(mirrors.size()):
		var mirror_data = level["mirrors"][index]
		mirrors[index].configure(
			mirror_data["position"],
			mirror_data["rotation"],
			mirror_data["can_rotate"],
			mirror_data["active"]
		)

	for index in range(obstacles.size()):
		var obstacle_data = level["obstacles"][index]
		obstacles[index].configure(
			obstacle_data["position"],
			obstacle_data["size"],
			obstacle_data["active"]
		)

	_select_first_available_mirror()
	beam.crystal_was_hit = false
	beam.recalculate_beam()
	_update_hud()


func _rotate_selected_mirror(direction: int) -> void:
	if selected_mirror == null:
		return

	selected_mirror.rotate_by_step(direction)
	rotation_count += 1
	_update_hud()


func _select_mirror_at_mouse() -> void:
	var mouse_position = get_global_mouse_position()

	for mirror in mirrors:
		if mirror.contains_global_point(mouse_position):
			_on_mirror_selected(mirror)
			return


func _select_next_mirror() -> void:
	var start_index = mirrors.find(selected_mirror)

	for step in range(1, mirrors.size() + 1):
		var index = (start_index + step) % mirrors.size()
		if mirrors[index].is_active and mirrors[index].can_rotate:
			_on_mirror_selected(mirrors[index])
			return


func _select_first_available_mirror() -> void:
	for mirror in mirrors:
		if mirror.is_active and mirror.can_rotate:
			_on_mirror_selected(mirror)
			return


func _on_mirror_selected(mirror) -> void:
	if completed or not mirror.is_active or not mirror.can_rotate:
		return

	for item in mirrors:
		item.set_selected(item == mirror)

	selected_mirror = mirror
	_update_hud()


func _on_mirror_rotated(_mirror) -> void:
	beam.recalculate_beam()


func _on_crystal_activated() -> void:
	completed = true
	feedback_label.text = "Cristal ativado! Fragmento recuperado!"
	_update_hud()
	_play_completion_animation()


func _update_hud() -> void:
	var level = levels[current_level]
	level_label.text = level["name"]
	objective_label.text = "Objetivo: " + level["objective"]
	movement_label.text = "Rotacoes: %d" % rotation_count
	state_label.text = "Estado: concluido" if completed else "Estado: jogando"
	progress_label.text = "Fragmentos: %d / %d" % [current_level + (1 if completed else 0), levels.size()]
	music_status_label.text = "Musica: ligada (M)" if music_player.is_music_enabled() else "Musica: desligada (M)"

	if completed:
		feedback_label.text = "Cristal ativado! N conclui o jogo, R reinicia." if current_level == levels.size() - 1 else "Cristal ativado! N avanca, R reinicia."
	elif selected_mirror != null:
		var mirror_number = mirrors.find(selected_mirror) + 1
		feedback_label.text = "Espelho %d: Q/E giram, Tab troca, R reinicia." % mirror_number
	else:
		feedback_label.text = "Use 1-4, Tab ou clique para selecionar espelhos moveis."


func _hide_completion_animation() -> void:
	if completion_tween != null:
		completion_tween.kill()
		completion_tween = null

	completion_shade.visible = false
	completion_shade.color = Color(0.02, 0.05, 0.08, 0.0)
	victory_label.visible = false
	victory_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	victory_label.scale = Vector2.ONE
	victory_hint_label.visible = false
	victory_hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	crystal.scale = Vector2.ONE


func _play_completion_animation() -> void:
	if completion_tween != null:
		completion_tween.kill()

	completion_shade.visible = true
	victory_label.visible = true
	victory_hint_label.visible = true
	completion_shade.color = Color(0.02, 0.05, 0.08, 0.0)
	victory_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	victory_label.scale = Vector2(0.78, 0.78)
	victory_hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	crystal.scale = Vector2.ONE

	completion_tween = create_tween()
	completion_tween.set_parallel(true)
	completion_tween.tween_property(completion_shade, "color:a", 0.58, 0.35)
	completion_tween.tween_property(victory_label, "modulate:a", 1.0, 0.28)
	completion_tween.tween_property(victory_label, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	completion_tween.tween_property(crystal, "scale", Vector2(1.22, 1.22), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	completion_tween.chain().tween_property(crystal, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	completion_tween.chain().tween_property(victory_hint_label, "modulate:a", 1.0, 0.3)


func _show_game_complete() -> void:
	_hide_completion_animation()
	get_tree().change_scene_to_file("res://scenes/game_complete.tscn")
