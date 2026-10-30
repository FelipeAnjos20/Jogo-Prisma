extends Node2D

# Controla uma fase: monta os objetos a partir de levels.gd, trata a entrada do jogador,
# verifica a vitoria e conversa com o HUD.

const MirrorScript := preload("res://scripts/mirror.gd")
const FilterScript := preload("res://scripts/color_filter.gd")
const CrystalScript := preload("res://scripts/crystal.gd")
const ObstacleScript := preload("res://scripts/obstacle.gd")
const PrismScript := preload("res://scripts/prism.gd")
const TutorialScript := preload("res://scripts/tutorial_pointer.gd")

const Feixe := preload("res://scripts/feixe.gd")

const ROOM_RECT := Feixe.SALA
const INTRO_TIME := 0.7
const IDLE_HINT_TIME := 45.0
const DRAG_THRESHOLD := 8.0
const DRAG_MIN_RADIUS := 22.0
const TOAST_SIZE := Vector2(640, 92)
const TOAST_ANCHORS := [
	Vector2(320, 96), Vector2(56, 104), Vector2(584, 104),
	Vector2(320, 590), Vector2(56, 590), Vector2(584, 590),
]

const INTRO_MESSAGES := [
	"Olá, eu sou Echo! O Prisma de Luz se partiu e cada sala guarda um fragmento. Gire o espelho para levar a luz até o cristal.",
	"Agora são dois espelhos. Troque entre eles com 1, 2, Tab ou clicando. Z desfaz o último giro.",
	"Cuidado: blocos vermelhos absorvem a luz. Você vai precisar dar a volta.",
	"Espelhos com cadeado não giram, mas continuam refletindo. Use-os a seu favor.",
	"O vidro roxo é um divisor: parte da luz atravessa e parte é refletida.",
	"Filtros tingem a luz branca. Cristais com anel colorido só acendem com a cor certa (▲ vermelho, ● verde, ■ azul).",
	"Luz colorida não atravessa filtro de outra cor. Planeje a ordem dos filtros.",
	"Três cristais! Cada ramo da luz tem um trabalho diferente.",
	"Isto é um prisma de verdade: ele separa a luz branca em vermelho, verde e azul.",
	"Último desafio! Combine prisma, divisor e filtro para acender todas as cores.",
]

@onready var camera: Camera2D = $Camera
@onready var emitter: Node2D = $Puzzle/Emitter
@onready var beam = $Puzzle/LightBeam
@onready var obstacles_root: Node2D = $Puzzle/Obstacles
@onready var filters_root: Node2D = $Puzzle/Filters
@onready var prisms_root: Node2D = $Puzzle/Prisms
@onready var mirrors_root: Node2D = $Puzzle/Mirrors
@onready var crystals_root: Node2D = $Puzzle/Crystals
@onready var hud = $HUD

var level_index := 0
var level: Dictionary = {}
var mirrors: Array = []
var rotatable: Array = []
var filters: Array = []
var obstacles: Array = []
var crystals: Array = []
var prisms: Array = []
var lit_state: Array = []

var selected: Node2D = null
var hovered: Node2D = null
var rotation_count := 0
var history: Array = []
var completed := false

var _intro_left := 0.0
var _level_time := 0.0
var _shake := 0.0
var _hint_used := false
var _hint_stage := 0
var _idle_hint_given := false
var _locked_tip_given := false
var _load_token := 0
var _tutorial: Node2D = null

# Arrastar para girar.
var _drag_mirror: Node2D = null
var _drag_origin := Vector2.ZERO
var _drag_moved := false
var _drag_angle_ready := false
var _drag_last_angle := 0.0
var _drag_accumulated := 0.0
var _drag_steps := 0
var _press_was_selected := false


func _ready() -> void:
	hud.pause_requested.connect(_pause)
	hud.resume_requested.connect(_resume)
	hud.restart_requested.connect(_restart)
	hud.hint_requested.connect(_show_hint)
	hud.next_requested.connect(_advance)
	hud.level_select_requested.connect(func() -> void: Transition.go_to("res://scenes/level_select.tscn"))
	hud.menu_requested.connect(func() -> void: Transition.go_to("res://scenes/menu.tscn"))
	hud.music_toggled.connect(_toggle_music)
	hud.set_music_state(GameState.music_enabled)

	Sfx.play_music("res://assets/audio/gameplay_music.mp3", -16.0)
	_load_level(clampi(GameState.current_level, 0, GameState.level_count() - 1))


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _notification(what: int) -> void:
	# Pausa automatica quando a janela perde o foco.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and GameState.autopause and is_inside_tree():
		if not completed and not get_tree().paused and not Transition.is_busy():
			_pause()


# ---------------------------------------------------------------- carregamento

func _load_level(index: int) -> void:
	_load_token += 1
	level_index = index
	GameState.current_level = index
	level = GameState.levels[index]

	completed = false
	rotation_count = 0
	history.clear()
	selected = null
	hovered = null
	_drag_mirror = null
	_intro_left = INTRO_TIME
	_level_time = 0.0
	_hint_used = false
	_hint_stage = 0
	_idle_hint_given = false
	_locked_tip_given = false
	get_tree().paused = false
	hud.show_pause(false)
	hud.hide_victory()
	hud.hide_toast()

	for root in [obstacles_root, filters_root, prisms_root, mirrors_root, crystals_root]:
		for child in root.get_children():
			root.remove_child(child)
			child.queue_free()
	mirrors.clear()
	rotatable.clear()
	filters.clear()
	obstacles.clear()
	crystals.clear()
	prisms.clear()
	lit_state.clear()

	emitter.position = level["emitter"]["position"]
	emitter.rotation_degrees = level["emitter"]["rotation"]

	for data in level["obstacles"]:
		var obstacle := ObstacleScript.new()
		obstacles_root.add_child(obstacle)
		obstacle.configure(data)
		obstacles.append(obstacle)

	for data in level["filters"]:
		var color_filter := FilterScript.new()
		filters_root.add_child(color_filter)
		color_filter.configure(data)
		filters.append(color_filter)

	for data in level.get("prisms", []):
		var prism := PrismScript.new()
		prisms_root.add_child(prism)
		prism.configure(data)
		prisms.append(prism)

	for data in level["mirrors"]:
		var mirror := MirrorScript.new()
		mirrors_root.add_child(mirror)
		var key_number := 0
		if data["can_rotate"]:
			rotatable.append(mirror)
			key_number = rotatable.size()
		mirror.configure(data, key_number)
		mirror.rotated.connect(_on_mirror_rotated)
		mirrors.append(mirror)

	for data in level["crystals"]:
		var crystal := CrystalScript.new()
		crystals_root.add_child(crystal)
		crystal.configure(data)
		crystals.append(crystal)
		lit_state.append(false)

	_pop_in([emitter] + obstacles + filters + prisms + mirrors + crystals)

	if not rotatable.is_empty():
		_select(rotatable[0], false)

	# Fase 1: seta animada mostrando qual espelho mexer, ate o primeiro giro.
	if _tutorial != null:
		_tutorial.queue_free()
		_tutorial = null
	if index == 0 and not rotatable.is_empty():
		_tutorial = TutorialScript.new()
		$Puzzle.add_child(_tutorial)
		_tutorial.target = rotatable[0]

	hud.set_toast_anchor(_best_toast_anchor())
	hud.setup_level(index, GameState.level_count(), level)
	_update_stats()

	var token := _load_token
	await get_tree().create_timer(1.6).timeout
	if token == _load_token and not completed and index < INTRO_MESSAGES.size():
		hud.show_toast("ECHO", INTRO_MESSAGES[index], 7.0)


func _pop_in(nodes: Array) -> void:
	for i in range(nodes.size()):
		var node: Node2D = nodes[i]
		node.scale = Vector2(0.05, 0.05)
		var tween := node.create_tween()
		tween.tween_interval(0.05 + i * 0.045)
		tween.tween_property(node, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _best_toast_anchor() -> Vector2:
	# Escolhe a posicao do aviso do Echo que cobre menos pecas (cristais pesam mais).
	var weighted: Array = []
	for node in [emitter] + obstacles + filters + prisms + mirrors:
		weighted.append([node.position, 1.0])
	for crystal in crystals:
		weighted.append([crystal.position, 3.0])

	var best_anchor: Vector2 = TOAST_ANCHORS[0]
	var best_score := INF
	for anchor in TOAST_ANCHORS:
		var area := Rect2(anchor, TOAST_SIZE).grow(40.0)
		var score := 0.0
		for entry in weighted:
			if area.has_point(entry[0]):
				score += float(entry[1])
		if score < best_score:
			best_score = score
			best_anchor = anchor
	return best_anchor


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if not completed:
		_level_time += delta
	_intro_left = maxf(0.0, _intro_left - delta)
	_update_hover()

	var lit: Array = beam.trace(emitter, mirrors, filters, obstacles, crystals, prisms, ROOM_RECT)
	for prism in prisms:
		prism.set_energized(beam.energized_prisms.has(prism))

	# Os cristais so mudam de estado com os espelhos parados, evitando "piscadas" durante o giro.
	if _intro_left <= 0.0 and _all_settled():
		var changed := false
		for i in range(crystals.size()):
			var on: bool = lit[i]
			if on != lit_state[i]:
				lit_state[i] = on
				crystals[i].set_lit(on)
				changed = true
				if not completed:
					Sfx.play("crystal_on" if on else "crystal_off", 1.0 + 0.1 * i)
		if changed:
			_update_stats()
		if not completed and _lit_count() == crystals.size():
			_complete_level()

	if not completed and not _hint_used and not _idle_hint_given and _level_time > IDLE_HINT_TIME:
		_idle_hint_given = true
		hud.show_toast("ECHO", "Travou? Aperte H (ou o botão Dica) e eu te dou uma pista.", 5.0)

	_shake = move_toward(_shake, 0.0, delta * 2.2)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 10.0 * _shake * _shake


func _all_settled() -> bool:
	for mirror in mirrors:
		if not mirror.is_settled():
			return false
	return true


func _lit_count() -> int:
	var total := 0
	for value in lit_state:
		if value:
			total += 1
	return total


func _update_stats() -> void:
	hud.update_stats(rotation_count, int(level["par"]), _lit_count(), crystals.size())


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if Transition.is_busy():
		return

	if event is InputEventMouseMotion:
		if _drag_mirror != null:
			_update_drag(get_global_mouse_position())
		return

	if event is InputEventJoypadButton:
		if event.pressed:
			_handle_joypad(event.button_index)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_position := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_press(mouse_position)
			else:
				_end_press()
			return
		if not event.pressed:
			return
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_click_mirror(mouse_position, -1)
			MOUSE_BUTTON_WHEEL_UP:
				_wheel_rotate(mouse_position, -1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_wheel_rotate(mouse_position, 1)
		return

	if not (event is InputEventKey and event.pressed):
		return

	var key: int = event.keycode
	var rotate_keys := [KEY_Q, KEY_E, KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]

	# Segurar Q/E gira continuamente; as outras teclas ignoram repeticao.
	if event.echo and not rotate_keys.has(key):
		return

	match key:
		KEY_ESCAPE, KEY_P:
			_pause()
		KEY_R:
			_restart()
		KEY_M:
			_toggle_music()
		KEY_H:
			_show_hint()
		KEY_N, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if completed:
				_advance()
		KEY_TAB:
			_cycle_selection(-1 if event.shift_pressed else 1)
		KEY_Z:
			_undo()
		KEY_Q, KEY_A, KEY_LEFT:
			_rotate_selected(-1)
		KEY_E, KEY_D, KEY_RIGHT:
			_rotate_selected(1)
		_:
			if key >= KEY_1 and key <= KEY_9:
				var index := key - KEY_1
				if index < rotatable.size() and not completed:
					_select(rotatable[index])
			else:
				return

	get_viewport().set_input_as_handled()


# Controle (Xbox/PlayStation): direcional gira, LB/RB trocam, A gira/continua, B desfaz,
# Y dica, X reinicia, Start pausa, Select liga/desliga a musica.
func _handle_joypad(button: int) -> void:
	match button:
		JOY_BUTTON_DPAD_LEFT:
			_rotate_selected(-1)
		JOY_BUTTON_DPAD_RIGHT:
			_rotate_selected(1)
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_DPAD_UP:
			_cycle_selection(-1)
		JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_DOWN:
			_cycle_selection(1)
		JOY_BUTTON_A:
			if completed:
				_advance()
			else:
				_rotate_selected(1)
		JOY_BUTTON_B:
			_undo()
		JOY_BUTTON_Y:
			_show_hint()
		JOY_BUTTON_X:
			_restart()
		JOY_BUTTON_START:
			_pause()
		JOY_BUTTON_BACK:
			_toggle_music()


func _mirror_at(global_point: Vector2) -> Node2D:
	for i in range(mirrors.size() - 1, -1, -1):
		if mirrors[i].contains_global_point(global_point):
			return mirrors[i]
	return null


func _update_hover() -> void:
	var mirror: Node2D = _drag_mirror
	if mirror == null and not completed:
		mirror = _mirror_at(get_global_mouse_position())
	if mirror == hovered:
		return
	if hovered != null:
		hovered.set_hovered(false)
	hovered = mirror
	if hovered != null:
		hovered.set_hovered(true)
	var pointer: bool = hovered != null and hovered.can_rotate
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if pointer else Input.CURSOR_ARROW)


# Clique esquerdo: seleciona; arrastar gira; clicar de novo no ja selecionado gira no sentido horario.
func _begin_press(global_point: Vector2) -> void:
	if completed:
		return
	var mirror := _mirror_at(global_point)
	if mirror == null:
		return
	if not mirror.can_rotate:
		_locked_feedback(mirror)
		return

	_press_was_selected = mirror == selected
	_select(mirror)
	_drag_mirror = mirror
	_drag_origin = global_point
	_drag_moved = false
	_drag_accumulated = 0.0
	_drag_steps = 0
	var offset := global_point - mirror.global_position
	_drag_angle_ready = offset.length() >= DRAG_MIN_RADIUS
	_drag_last_angle = offset.angle()


func _update_drag(global_point: Vector2) -> void:
	var mirror := _drag_mirror
	if completed:
		_drag_mirror = null
		return
	if not _drag_moved and global_point.distance_to(_drag_origin) < DRAG_THRESHOLD:
		return
	_drag_moved = true

	var offset := global_point - mirror.global_position
	if offset.length() < DRAG_MIN_RADIUS:
		return
	var angle := offset.angle()
	if not _drag_angle_ready:
		_drag_angle_ready = true
		_drag_last_angle = angle
		return

	_drag_accumulated += wrapf(angle - _drag_last_angle, -PI, PI)
	_drag_last_angle = angle

	var step: float = MirrorScript.STEP_DEGREES
	# Converte o giro do mouse em passos de 15 graus (ver docs/adr/002).
	var desired := int(round(rad_to_deg(_drag_accumulated) / step))
	while _drag_steps < desired:
		mirror.rotate_step(1)
		_drag_steps += 1
	while _drag_steps > desired:
		mirror.rotate_step(-1)
		_drag_steps -= 1


func _end_press() -> void:
	if _drag_mirror != null and not _drag_moved and _press_was_selected:
		_rotate_selected(1)
	_drag_mirror = null


func _click_mirror(global_point: Vector2, direction: int) -> void:
	if completed:
		return
	var mirror := _mirror_at(global_point)
	if mirror == null:
		return
	if not mirror.can_rotate:
		_locked_feedback(mirror)
		return
	_select(mirror)
	_rotate_selected(direction)


func _wheel_rotate(global_point: Vector2, direction: int) -> void:
	if completed:
		return
	var mirror := _mirror_at(global_point)
	if mirror != null and mirror.can_rotate and mirror != selected:
		_select(mirror, false)
	elif mirror != null and not mirror.can_rotate:
		_locked_feedback(mirror)
		return
	_rotate_selected(direction)


func _locked_feedback(mirror: Node2D) -> void:
	mirror.shake_locked()
	Sfx.play("locked")
	if not _locked_tip_given:
		_locked_tip_given = true
		hud.show_toast("ECHO", "Esse espelho está travado: ele reflete a luz, mas não gira.", 3.5)


func _select(mirror: Node2D, with_sound := true) -> void:
	if mirror == null or not mirror.can_rotate:
		return
	for item in mirrors:
		item.set_selected(item == mirror)
	if with_sound and mirror != selected:
		Sfx.play("select")
	selected = mirror


func _cycle_selection(step: int) -> void:
	if completed or rotatable.is_empty():
		return
	var index := rotatable.find(selected)
	index = posmod(index + step, rotatable.size())
	_select(rotatable[index])


func _rotate_selected(direction: int) -> void:
	if completed or selected == null or get_tree().paused:
		return
	selected.rotate_step(direction)


func _on_mirror_rotated(mirror: Node2D, previous_degrees: float) -> void:
	if _tutorial != null:
		_tutorial.dismiss()
		_tutorial = null
	history.append([mirror, previous_degrees])
	rotation_count += 1
	Sfx.play("rotate", randf_range(0.92, 1.1))
	_update_stats()


func _undo() -> void:
	if completed or history.is_empty():
		return
	var entry: Array = history.pop_back()
	var mirror: Node2D = entry[0]
	mirror.restore_rotation(entry[1])
	rotation_count = maxi(0, rotation_count - 1)
	_select(mirror, false)
	Sfx.play("undo")
	_update_stats()


# ---------------------------------------------------------------- dicas

# 1a vez: dica em texto. A partir da 2a: mostra o angulo certo de um espelho que ainda esta errado.
func _show_hint() -> void:
	if completed:
		return
	_hint_used = true
	Sfx.play("hint")

	if _hint_stage == 0:
		_hint_stage = 1
		hud.show_toast("DICA DO ECHO", "%s\n(Aperte H de novo e eu mostro o ângulo de um espelho.)" % level["hint"], 9.0)
		return

	var mirror := _next_wrong_mirror()
	if mirror == null:
		hud.show_toast("DICA DO ECHO", "Os ângulos já estão certos! Espere a luz se acomodar.", 4.0)
		return
	var index := mirrors.find(mirror)
	mirror.show_ghost(float(level["solution"][index]))
	_select(mirror)
	hud.show_toast("DICA DO ECHO", "Gire o espelho %d até o contorno verde pontilhado." % mirror.number, 6.0)


func _next_wrong_mirror() -> Node2D:
	var solution: Array = level.get("solution", [])
	var fallback: Node2D = null
	for i in range(mirrors.size()):
		var mirror: Node2D = mirrors[i]
		if not mirror.can_rotate or i >= solution.size():
			continue
		if mirror.matches_angle(float(solution[i])):
			continue
		if not mirror.has_ghost:
			return mirror
		if fallback == null:
			fallback = mirror
	return fallback


# ---------------------------------------------------------------- fluxo

func _complete_level() -> void:
	completed = true
	_drag_mirror = null
	var token := _load_token
	var result := GameState.record_result(level_index, rotation_count)
	var is_last := level_index == GameState.level_count() - 1

	for mirror in mirrors:
		mirror.set_selected(false)
		mirror.has_ghost = false
	_shake = 1.0
	hud.flash(0.5)
	hud.hide_toast()
	Sfx.play("win")

	await get_tree().create_timer(1.0).timeout
	if token != _load_token:
		return
	hud.show_victory(result, rotation_count, int(level["par"]), is_last, _level_time)


func _advance() -> void:
	if not completed or Transition.is_busy():
		return
	if level_index >= GameState.level_count() - 1:
		Transition.go_to("res://scenes/game_complete.tscn")
	else:
		Transition.fade_call(_load_level.bind(level_index + 1))


func _restart() -> void:
	if Transition.is_busy():
		return
	get_tree().paused = false
	hud.show_pause(false)
	Transition.fade_call(_load_level.bind(level_index))


func _pause() -> void:
	if Transition.is_busy():
		return
	_drag_mirror = null
	get_tree().paused = true
	hud.show_pause(true)
	Sfx.play("click")


func _resume() -> void:
	get_tree().paused = false
	hud.show_pause(false)
	Sfx.play("click")


func _toggle_music() -> void:
	var enabled := GameState.toggle_music()
	hud.set_music_state(enabled)
	if not get_tree().paused:
		hud.show_toast("ECHO", "Música ligada." if enabled else "Música desligada.", 1.5)
