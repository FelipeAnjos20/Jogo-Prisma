extends Node2D

# Controla uma fase: monta os objetos a partir de levels.gd, trata a entrada do jogador,
# verifica a vitoria e conversa com o HUD.

const MirrorScript := preload("res://scripts/mirror.gd")
const FilterScript := preload("res://scripts/color_filter.gd")
const CrystalScript := preload("res://scripts/crystal.gd")
const ObstacleScript := preload("res://scripts/obstacle.gd")
const PrismScript := preload("res://scripts/prism.gd")
const TutorialScript := preload("res://scripts/tutorial_pointer.gd")
const AngleGuideScript := preload("res://scripts/angle_guide.gd")
const EchoBrain := preload("res://scripts/echo_brain.gd")
const Geometria = preload("res://scripts/geometria.gd")
const UI := preload("res://scripts/ui_kit.gd")
const Musica := preload("res://scripts/musica.gd")

const Feixe := preload("res://scripts/feixe.gd")

const ROOM_RECT := Feixe.SALA
const INTRO_TIME := 0.7
const IDLE_HINT_TIME := 45.0
const TOOLTIP_DELAY := 0.35
# Sem nenhuma acao do jogador por este tempo, o Echo da barra superior cochila.
const SLEEP_TIME := 30.0
# Distancia (da borda do cristal) para o Echo dizer "Quase!" e variacoes para o "quente ou frio".
const NEAR_MISS_DISTANCE := 100.0
const WARMER_DELTA := 60.0
const COLDER_DELTA := 150.0
const WARM_COLD_INTERVAL := 6.0
const COLOR_SYMBOLS := {"red": "▲", "green": "●", "blue": "■"}
const COLOR_FEMININE := {"red": "vermelha", "green": "verde", "blue": "azul"}

# Prioridade das falas do Echo: uma fala so interrompe outra de prioridade menor ou igual.
const PRIORITY_REACTION := 1
const PRIORITY_EVENT := 2
const PRIORITY_HINT := 3
const DRAG_THRESHOLD := 8.0
const DRAG_MIN_RADIUS := 22.0
const TOAST_SIZE := Vector2(560, 92)
const TOAST_ANCHORS := [
	Vector2(360, 96), Vector2(56, 104), Vector2(664, 104),
	Vector2(360, 590), Vector2(56, 590), Vector2(664, 590),
]
# A cada tantos pixels do raio, um ponto conta como "coberto" pelo balao.
const TOAST_BEAM_STEP := 40.0

const INTRO_MESSAGES := [
	"Olá, {nome}! Eu sou Echo. O Prisma de Luz se partiu e cada sala guarda um fragmento. Gire o espelho para levar a luz até o cristal.",
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

# Echo que conversa e reage
var _echo := EchoBrain.new()
var _toast_priority := 0
var _toast_until := 0.0
var _best_lit := 0
var _rotations_since_progress := 0
var _struggle_tip_given := false
var _revisit_tip_given := false
var _config_visits := {}
var _reacted_config := ""
var _wrong_color_warned := {}
var _last_closest := INF
var _last_warm_cold := -100.0
var _last_near_said := -1
var _last_input := 0.0
var _wake_said := false

# Guia de angulos e caixa de informacao
var _angle_guide: Node2D = null
var _hover_key := ""
var _hover_time := 0.0
var _victory_reflections: Array = []

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
	hud.echo_clicked.connect(_open_echo_menu)
	hud.choice_made.connect(_on_choice)
	hud.set_music_state(GameState.music_enabled)
	_echo.player_name = GameState.player_name

	Sfx.play_music("res://assets/audio/gameplay_music.mp3", -16.0)
	_angle_guide = AngleGuideScript.new()
	$Puzzle.add_child(_angle_guide)
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
	_toast_priority = 0
	_toast_until = 0.0
	_best_lit = 0
	_rotations_since_progress = 0
	_struggle_tip_given = false
	_revisit_tip_given = false
	_config_visits.clear()
	_reacted_config = ""
	_wrong_color_warned.clear()
	_last_closest = INF
	_last_warm_cold = -100.0
	_last_near_said = -1
	_hover_key = ""
	_hover_time = 0.0
	_last_input = _now()
	_wake_said = false
	get_tree().paused = false
	hud.hide_choice()
	hud.set_buddy_sleepy(false)
	hud.hide_tooltip()
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

	# Calcula o raio da fase nova antes de escolher onde o Echo fala.
	beam.trace(emitter, mirrors, filters, obstacles, crystals, prisms, ROOM_RECT)
	hud.set_toast_anchor(_best_toast_anchor())
	hud.setup_level(index, GameState.level_count(), level)
	_update_stats()

	var token := _load_token
	await get_tree().create_timer(1.6).timeout
	if token != _load_token or completed:
		return
	# Na fase 2 (so na primeira vez) o Echo pergunta como o jogador prefere ser ajudado.
	if index == 1 and GameState.echo_help == "":
		hud.ask("help", EchoBrain.personalizar("Agora que você pegou o jeito, {nome}: quer que eu dê pistas quando você travar?", GameState.player_name), ["Sim, me ajuda!", "Deixa comigo!"])
		return
	_say_intro()


func _say_intro() -> void:
	if level_index < INTRO_MESSAGES.size():
		_say(EchoBrain.personalizar(INTRO_MESSAGES[level_index], GameState.player_name), 7.0, "neutral", PRIORITY_EVENT)


func _pop_in(nodes: Array) -> void:
	for i in range(nodes.size()):
		var node: Node2D = nodes[i]
		node.scale = Vector2(0.05, 0.05)
		var tween := node.create_tween()
		tween.tween_interval(0.05 + i * 0.045)
		tween.tween_property(node, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _best_toast_anchor() -> Vector2:
	# Escolhe a posicao do aviso do Echo que cobre menos pecas (cristais e o espelho
	# selecionado pesam mais) e menos do caminho atual da luz.
	var weighted: Array = []
	for node in [emitter] + obstacles + filters + prisms + mirrors:
		weighted.append([node.position, 2.5 if node == selected else 1.0])
	for crystal in crystals:
		weighted.append([crystal.position, 3.0])
	for segment in beam.segments:
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		var steps := int(a.distance_to(b) / TOAST_BEAM_STEP)
		for i in range(steps + 1):
			weighted.append([a.lerp(b, float(i) / maxf(1.0, float(steps))), 0.25])

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
		var turned_on := false
		var turned_off := false
		for i in range(crystals.size()):
			var on: bool = lit[i]
			if on != lit_state[i]:
				lit_state[i] = on
				crystals[i].set_lit(on)
				changed = true
				turned_on = turned_on or on
				turned_off = turned_off or not on
				if not completed and not on:
					Sfx.play("crystal_off", 1.0 + 0.1 * i)
		if turned_on and not completed:
			# A luz vira musica: cada cristal aceso toca a proxima nota do acorde.
			Sfx.play_tone(Musica.nota_do_cristal(_lit_count() - 1))
		if changed:
			_update_stats()
		if not completed and _lit_count() == crystals.size():
			_complete_level()
		elif not completed:
			_react_to_crystals(turned_on, turned_off)
			_react_to_configuration()

	if not completed and not _hint_used and not _idle_hint_given and _level_time > IDLE_HINT_TIME:
		_idle_hint_given = true
		if _allowed("idle"):
			_say(_echo.say("idle"), 5.0, "thinking", PRIORITY_REACTION)

	_update_near_crystals()
	hud.set_buddy_sleepy(not completed and not get_tree().paused and _now() - _last_input > SLEEP_TIME)

	var guide_target: Node2D = selected if selected != null else hovered
	_angle_guide.update_guide(null if completed else guide_target, beam.reflections, GameState.show_angles)
	_update_tooltip(delta)

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
	_register_activity(event)

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

	# Com uma pergunta do Echo aberta, as teclas 1 a 4 escolhem a resposta.
	if hud.is_choice_open() and not event.echo and key >= KEY_1 and key < KEY_1 + hud.choice_count():
		hud.choose(key - KEY_1)
		get_viewport().set_input_as_handled()
		return

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
		KEY_G:
			_toggle_angles()
		KEY_T:
			if not event.echo:
				_open_echo_menu()
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
		_say("Esse espelho está travado: ele reflete a luz, mas não gira.", 3.5, "surprised", PRIORITY_EVENT)


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
	_rotations_since_progress += 1
	_last_input = _now()
	# O espelho "canta": cada posicao tem um tom.
	Sfx.play("rotate", Musica.pitch_do_angulo(mirror.target_degrees))
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
		_say("%s\n(Aperte H de novo e eu mostro o ângulo de um espelho.)" % level["hint"], 9.0, "thinking", PRIORITY_HINT, "DICA DO ECHO")
		return

	var mirror := _next_wrong_mirror()
	if mirror == null:
		_say("Os ângulos já estão certos! Espere a luz se acomodar.", 4.0, "happy", PRIORITY_HINT, "DICA DO ECHO")
		return
	var index := mirrors.find(mirror)
	mirror.show_ghost(float(level["solution"][index]))
	_select(mirror)
	_say("Gire o espelho %d até o contorno verde pontilhado." % mirror.number, 6.0, "thinking", PRIORITY_HINT, "DICA DO ECHO")


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

	var explanation_reflections: Array = beam.reflections.duplicate()
	for mirror in mirrors:
		mirror.set_selected(false)
		mirror.has_ghost = false
	_victory_reflections = explanation_reflections
	hud.hide_tooltip()
	hud.hide_choice()
	_shake = 1.0
	hud.flash(0.5)
	hud.hide_toast()
	beam.celebrate()
	# Cada fase termina com a sua melodia (ver scripts/musica.gd).
	get_tree().create_timer(0.25).timeout.connect(Sfx.play_melody.bind("win_%d" % level_index, Musica.melodia_da_fase(level_index)))

	await get_tree().create_timer(1.0).timeout
	if token != _load_token:
		return
	var comment: String = _echo.victory_comment(int(result["stars"]), rotation_count, int(level["par"]), _hint_used, bool(result["record"]), _level_time)
	# Na primeira vez que a fase e concluida, o fragmento devolve uma memoria da historia.
	var story_index := level_index if bool(result.get("first_clear", false)) else -1
	hud.show_victory(result, rotation_count, int(level["par"]), is_last, _level_time, comment, _build_explanation(), story_index)


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
		_say("Música ligada." if enabled else "Música desligada.", 1.5, "neutral", PRIORITY_REACTION)



# ---------------------------------------------------------------- Echo que conversa e reage

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# Mostra uma fala do Echo respeitando a prioridade da fala que esta na tela.
func _say(text: String, duration: float, mood: String, priority: int, title := "ECHO") -> bool:
	if _now() < _toast_until and priority < _toast_priority:
		return false
	_toast_priority = priority
	_toast_until = _now() + duration + text.length() * 0.022
	# O lugar do balao e escolhido a cada fala, porque o raio muda a cada giro.
	if not hud.is_toast_visible():
		hud.set_toast_anchor(_best_toast_anchor())
	hud.show_toast(title, text, duration, mood)
	return true


func _react_to_crystals(turned_on: bool, turned_off: bool) -> void:
	var lit := _lit_count()
	if lit > _best_lit:
		_best_lit = lit
		_rotations_since_progress = 0
	if turned_on and crystals.size() > 1:
		var remaining := crystals.size() - lit
		var remaining_text := "Falta só 1." if remaining == 1 else "Faltam %d." % remaining
		_say(_echo.say("crystal_on", [remaining_text]), 3.5, "happy", PRIORITY_EVENT)
	elif turned_off and rotation_count > 0:
		_say(_echo.say("crystal_off"), 3.5, "surprised", PRIORITY_EVENT)


# Roda uma vez para cada nova posicao dos espelhos (depois que eles param de girar).
func _react_to_configuration() -> void:
	var signature := _configuration_signature()
	if signature == _reacted_config:
		return
	_reacted_config = signature
	if rotation_count == 0:
		return

	_config_visits[signature] = int(_config_visits.get(signature, 0)) + 1
	if _config_visits[signature] >= 3 and not _revisit_tip_given and _allowed("revisit"):
		_revisit_tip_given = true
		_say(_echo.say("revisit"), 4.5, "thinking", PRIORITY_REACTION)
		return

	if not _struggle_tip_given and not _hint_used and _rotations_since_progress >= maxi(8, int(level["par"]) * 2) and _allowed("struggle"):
		_struggle_tip_given = true
		_say(_echo.say("struggle"), 5.0, "thinking", PRIORITY_REACTION)
		return

	_react_to_beam()


# Reage ao caminho da luz depois de cada giro:
# cor errada > "Quase!" (passou perto) > "quente ou frio" (aproximou ou afastou do cristal).
func _react_to_beam() -> void:
	var overall_closest := INF
	var near_message := ""
	var near_distance := -1
	for i in range(crystals.size()):
		if lit_state[i]:
			continue
		var crystal: Node2D = crystals[i]
		var center := crystal.global_position
		var radius: float = crystal.get_light_radius()
		var closest := INF
		var touched := false
		for segment in beam.segments:
			var a: Vector2 = segment["a"]
			var b: Vector2 = segment["b"]
			closest = minf(closest, center.distance_to(Geometry2D.get_closest_point_to_segment(center, a, b)))
			if b.distance_to(center) <= radius + 1.5:
				touched = true
		var color_name: String = crystal.required_color
		if touched and color_name != "any":
			if not _wrong_color_warned.has(i):
				_wrong_color_warned[i] = true
				_say(_echo.say("wrong_color", [COLOR_FEMININE.get(color_name, color_name), COLOR_SYMBOLS.get(color_name, "")]), 4.5, "thinking", PRIORITY_REACTION)
				return
			continue
		var edge_distance := maxf(0.0, closest - radius)
		overall_closest = minf(overall_closest, edge_distance)
		# So comenta de novo se a distancia mudou (girar outro espelho nao repete o mesmo "Quase!").
		var rounded := int(round(edge_distance))
		if near_message == "" and edge_distance > 0.0 and edge_distance < NEAR_MISS_DISTANCE and rounded != _last_near_said and _allowed("near_miss"):
			near_message = _echo.say("near_miss", [rounded])
			near_distance = rounded

	var previous := _last_closest
	_last_closest = overall_closest
	if _now() - _last_warm_cold < WARM_COLD_INTERVAL:
		return
	if near_message != "":
		if _say(near_message, 4.0, "surprised", PRIORITY_REACTION):
			_last_warm_cold = _now()
			_last_near_said = near_distance
		return
	if previous == INF or overall_closest == INF or not _allowed("warmer"):
		return
	if overall_closest < previous - WARMER_DELTA and overall_closest < 250.0:
		if _say(_echo.say("warmer"), 3.5, "happy", PRIORITY_REACTION):
			_last_warm_cold = _now()
	elif overall_closest > previous + COLDER_DELTA and previous < 150.0:
		if _say(_echo.say("colder"), 3.5, "thinking", PRIORITY_REACTION):
			_last_warm_cold = _now()


func _allowed(key: String) -> bool:
	return EchoBrain.fala_permitida(key, GameState.echo_help)


# Distancia do raio ate a borda do cristal (0 quando o raio encosta nele).
func _beam_distance(crystal: Node2D) -> float:
	var center := crystal.global_position
	var closest := INF
	for segment in beam.segments:
		closest = minf(closest, center.distance_to(Geometry2D.get_closest_point_to_segment(center, segment["a"], segment["b"])))
	return maxf(0.0, closest - crystal.get_light_radius())


# "Quase la": cristais apagados tremem e brilham fraco quando o raio passa perto.
func _update_near_crystals() -> void:
	for i in range(crystals.size()):
		var crystal: Node2D = crystals[i]
		if completed or lit_state[i]:
			crystal.near = 0.0
			continue
		crystal.near = clampf(1.0 - _beam_distance(crystal) / NEAR_MISS_DISTANCE, 0.0, 1.0)


func _register_activity(event: InputEvent) -> void:
	var active := event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton
	if event is InputEventMouseMotion:
		active = event.relative.length() > 2.0
	if not active:
		return
	var was_sleeping := _now() - _last_input > SLEEP_TIME
	_last_input = _now()
	if was_sleeping and not completed and not _wake_said:
		_wake_said = true
		_say(_echo.say("wake"), 3.0, "surprised", PRIORITY_REACTION)


# ---------------------------------------------------------------- conversa com o Echo

func _open_echo_menu() -> void:
	if completed or get_tree().paused or Transition.is_busy():
		return
	if hud.is_choice_open():
		if hud.choice_tag() == "echo":
			hud.hide_choice()
		return
	Sfx.play("talk", 1.2)
	var quiet := GameState.echo_help == "sozinho"
	if not hud.is_toast_visible():
		hud.set_toast_anchor(_best_toast_anchor())
	hud.ask("echo", _echo.say("pet"), ["Uma dica", "Uma curiosidade", "Pode me ajudar" if quiet else "Fale menos", "Nada, valeu!"])


func _on_choice(tag: String, index: int) -> void:
	Sfx.play("click")
	match tag:
		"help":
			GameState.set_echo_help("ajuda" if index == 0 else "sozinho")
			_say(_echo.say("help_yes" if index == 0 else "help_no"), 3.0, "happy", PRIORITY_EVENT)
			var token := _load_token
			await get_tree().create_timer(3.4).timeout
			if token == _load_token and not completed:
				_say_intro()
		"echo":
			match index:
				0:
					_show_hint()
				1:
					_say(_echo.say("curiosity"), 7.0, "happy", PRIORITY_HINT, "CURIOSIDADE")
				2:
					var quiet := GameState.echo_help == "sozinho"
					GameState.set_echo_help("ajuda" if quiet else "sozinho")
					_say(_echo.say("help_yes" if quiet else "help_no"), 3.5, "happy", PRIORITY_HINT)
				_:
					_say(_echo.say("bye"), 2.5, "happy", PRIORITY_HINT)


func _configuration_signature() -> String:
	var parts: Array = []
	for mirror in rotatable:
		parts.append(str(int(round(fposmod(mirror.target_degrees, 180.0)))))
	return ",".join(parts)


func _toggle_angles() -> void:
	GameState.set_show_angles(not GameState.show_angles)
	Sfx.play("click")
	_say(_echo.say("angles_on" if GameState.show_angles else "angles_off"), 2.5, "neutral", PRIORITY_REACTION)


# ---------------------------------------------------------------- caixa de informacao das pecas

func _update_tooltip(delta: float) -> void:
	if completed or get_tree().paused or _drag_mirror != null:
		_hover_key = ""
		hud.hide_tooltip()
		return
	var info := _element_info_at(get_global_mouse_position())
	if info.is_empty():
		_hover_key = ""
		_hover_time = 0.0
		hud.hide_tooltip()
		return
	if info["key"] != _hover_key:
		_hover_key = info["key"]
		_hover_time = 0.0
		hud.hide_tooltip()
	_hover_time += delta
	if _hover_time >= TOOLTIP_DELAY:
		hud.show_tooltip(info["title"], info["body"], get_viewport().get_mouse_position())


func _element_info_at(point: Vector2) -> Dictionary:
	for i in range(mirrors.size() - 1, -1, -1):
		var mirror: Node2D = mirrors[i]
		if mirror.contains_global_point(point):
			var angle := int(round(Geometria.inclinacao_espelho(mirror.target_degrees))) % 180
			if mirror.is_splitter():
				return {"key": "m%d" % i, "title": "Divisor de feixe" + ("" if mirror.can_rotate else " (travado)"),
					"body": "Vidro semi-espelhado: parte da luz atravessa reta e parte é refletida, criando dois raios. Inclinação: %d°." % angle}
			if mirror.can_rotate:
				return {"key": "m%d" % i, "title": "Espelho %d" % mirror.number,
					"body": "Reflete a luz: o ângulo de incidência é igual ao de reflexão. Inclinação: %d°. Clique para selecionar; arraste a ponta, use Q/E ou a roda para girar 15°." % angle}
			return {"key": "m%d" % i, "title": "Espelho travado",
				"body": "Reflete a luz, mas não gira. Inclinação: %d°. Use os outros espelhos para levar a luz até ele." % angle}

	for i in range(crystals.size()):
		var crystal: Node2D = crystals[i]
		if crystal.global_position.distance_to(point) <= crystal.get_light_radius() + 8.0:
			var color_name: String = crystal.required_color
			var state := "Agora: aceso." if lit_state[i] else "Agora: apagado."
			if color_name == "any":
				return {"key": "c%d" % i, "title": "Cristal", "body": "Acende com luz de qualquer cor. %s" % state}
			var label := "%s %s" % [UI.COLOR_NAMES.get(color_name, color_name), COLOR_SYMBOLS.get(color_name, "")]
			var light := "%s %s" % [COLOR_FEMININE.get(color_name, color_name), COLOR_SYMBOLS.get(color_name, "")]
			return {"key": "c%d" % i, "title": "Cristal %s" % label, "body": "Só acende com luz %s. %s" % [light, state]}

	for i in range(prisms.size()):
		if prisms[i].global_position.distance_to(point) <= 36.0:
			return {"key": "p%d" % i, "title": "Prisma",
				"body": "Separa a luz branca em três: vermelho ▲ (30° para um lado), verde ● (reto) e azul ■ (30° para o outro). Luz colorida atravessa reto."}

	for i in range(filters.size()):
		var color_filter: Node2D = filters[i]
		var local := color_filter.to_local(point)
		if absf(local.x) <= 58.0 and absf(local.y) <= 16.0:
			var color_name: String = color_filter.color_name
			return {"key": "f%d" % i, "title": "Filtro %s %s" % [UI.COLOR_NAMES.get(color_name, color_name), COLOR_SYMBOLS.get(color_name, "")],
				"body": "A luz branca sai %s ao atravessar. Luz da mesma cor passa; luz de outra cor é bloqueada." % COLOR_FEMININE.get(color_name, color_name)}

	for i in range(obstacles.size()):
		var obstacle: Node2D = obstacles[i]
		var local := obstacle.to_local(point)
		var half: Vector2 = obstacle.obstacle_size * 0.5
		if absf(local.x) <= half.x and absf(local.y) <= half.y:
			return {"key": "o%d" % i, "title": "Bloco absorvedor", "body": "Absorve qualquer raio de luz que o toca. Contorne-o com os espelhos."}

	var emitter_local := emitter.to_local(point)
	if emitter_local.x >= -46.0 and emitter_local.x <= 34.0 and absf(emitter_local.y) <= 26.0:
		return {"key": "e", "title": "Emissor", "body": "Fonte da luz branca. A direção do raio não muda: quem muda o caminho são os espelhos."}
	return {}


# ---------------------------------------------------------------- "Por que funcionou?"

func _build_explanation() -> String:
	var lines: Array = []
	var count := _victory_reflections.size()
	if count > 0:
		lines.append("Na sua solução a luz refletiu %d %s:" % [count, "vez" if count == 1 else "vezes"])
		for i in range(mini(count, 4)):
			var reflection: Dictionary = _victory_reflections[i]
			var angle := int(round(float(reflection["angle"])))
			lines.append("•  %s: incidência %d° = reflexão %d°, então o raio virou %d°." % [_mirror_name(reflection["mirror"]), angle, angle, 180 - 2 * angle])
		if count > 4:
			lines.append("•  ... e mais %d reflexões." % (count - 4))

	var has_splitter := false
	for mirror in mirrors:
		has_splitter = has_splitter or mirror.is_splitter()
	if has_splitter:
		lines.append("O divisor criou dois caminhos: parte da luz seguiu reto e parte foi refletida.")
	if not filters.is_empty():
		lines.append("O filtro tingiu a luz branca, e só a cor certa acende cada cristal colorido.")
	if not prisms.is_empty():
		lines.append("O prisma separou a luz branca: vermelho 30° para um lado, verde reto e azul 30° para o outro.")
	lines.append("Regra de ouro: o ângulo de incidência é sempre igual ao ângulo de reflexão.")
	return "\n".join(lines)


func _mirror_name(mirror: Node2D) -> String:
	if mirror.is_splitter():
		return "Divisor %d" % mirror.number if mirror.number > 0 else "Divisor"
	if mirror.number > 0:
		return "Espelho %d" % mirror.number
	return "Espelho travado"
