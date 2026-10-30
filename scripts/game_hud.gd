extends CanvasLayer

# Interface da fase: barra superior, avisos do Echo, painel de vitoria e menu de pausa.
# Toda a UI e montada por codigo para ficar facil de ajustar.

signal pause_requested
signal resume_requested
signal restart_requested
signal hint_requested
signal next_requested
signal level_select_requested
signal menu_requested
signal music_toggled
signal echo_clicked
# tag identifica a pergunta; index e a opcao escolhida.
signal choice_made(tag: String, index: int)

const UI := preload("res://scripts/ui_kit.gd")
const EchoFace := preload("res://scripts/echo_face.gd")
const Historia := preload("res://scripts/historia.gd")

var _level_title: Label
var _objective: Label
var _rotations_label: Label
var _goal_label: Label
var _crystals_label: Label
var _gems: GemRow
var _music_button: Button

var _toast_holder: Control
var _toast: PanelContainer
var _toast_label: Label
var _toast_title: Label
var _toast_tween: Tween
var _toast_anchor := Vector2(360, 96)
var _toast_icon: EchoFace
var _typing := false
var _typed_chars := 0

var _tooltip: PanelContainer
var _tooltip_title: Label
var _tooltip_body: Label

var _banner: VBoxContainer
var _banner_title: Label
var _banner_name: Label

var _flash: ColorRect
var _logo: PrismLogo

var _victory_root: Control
var _victory_card: PanelContainer
var _victory_title: Label
var _victory_stars: StarRow
var _victory_info: Label
var _victory_record: Label
var _next_button: Button
var _victory_echo: Label
var _victory_echo_icon: EchoFace
var _why_button: Button
var _why_label: Label
var _story_box: PanelContainer
var _story_title: Label
var _story_text: Label
var _story_image: TextureRect

# Echo da barra superior: sempre visivel, olha para o mouse e abre a conversa ao ser clicado.
var _buddy: EchoFace
var _buddy_mood_until := 0.0
var _buddy_sleepy := false
# Na dica, um Echo "voador" sai da barra e vai ate o espelho certo.
var _flyer: EchoFace
var _flyer_tween: Tween

# Pergunta do Echo com botoes de resposta.
var _choice_holder: Control
var _choice_label: Label
var _choice_buttons: HBoxContainer
var _choice_tag := ""

var _pause_root: Control
var _resume_button: Button

var _help_label: Label
var _help_pad_mode := false
var _help_mouse := ""

# Largura do balao de fala do Echo (o main.gd usa para escolher onde ele atrapalha menos).
const TOAST_WIDTH := 560.0
const CHOICE_WIDTH := 640.0

# Atalhos do mouse/teclado, liberados aos poucos: [primeira fase em que aparece, texto].
const HELP_STEPS := [
	[0, "Clique: selecionar"],
	[0, "Arrastar, Q/E ou roda: girar"],
	[0, "H: dica"],
	[1, "1-9 / Tab: trocar"],
	[1, "Z: desfazer"],
	[2, "T: falar com o Echo"],
	[2, "G: ângulos"],
	[3, "M: música"],
]
const HELP_PAD :="Controle:  ◀ ▶ girar   ·   LB / RB trocar espelho   ·   A girar   ·   B desfazer   ·   Y dica   ·   X reiniciar   ·   Start pausa"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top_bar()
	_build_bottom_help()
	_build_toast()
	_flyer = EchoFace.new(17.0)
	_flyer.visible = false
	_flyer.size = _flyer.custom_minimum_size
	add_child(_flyer)
	_build_choice()
	_build_tooltip()
	_build_banner()
	_build_flash()
	_build_victory()
	_build_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not _pause_root.visible:
		return
	var resume := false
	if event is InputEventKey and event.pressed and not event.echo:
		resume = event.keycode == KEY_ESCAPE or event.keycode == KEY_P
	elif event is InputEventJoypadButton and event.pressed:
		resume = event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_B
	if resume:
		resume_requested.emit()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- API usada pelo main.gd

func setup_level(index: int, total: int, level: Dictionary) -> void:
	_level_title.text = "Fase %d de %d  ·  %s" % [index + 1, total, level["name"]]
	_objective.text = level["objective"]
	_goal_label.text = "Meta ★★★: até %d rotações" % int(level["par"])
	_help_mouse = help_for_level(index)
	_help_label.text = HELP_PAD if _help_pad_mode else _help_mouse
	_show_banner("FASE %d" % (index + 1), level["name"])


# Linha de atalhos da fase: so o que o jogador ja aprendeu, para nao encher a tela de texto.
static func help_for_level(index: int) -> String:
	var parts: Array = []
	for step in HELP_STEPS:
		if index >= int(step[0]):
			parts.append(step[1])
	return "   ·   ".join(parts)


func update_stats(rotations: int, par: int, lit: int, total_crystals: int) -> void:
	_rotations_label.text = "Rotações: %d" % rotations
	_rotations_label.label_settings.font_color = UI.TEXT if rotations <= par else (UI.ACCENT if rotations <= par * 2 else UI.DANGER)
	_crystals_label.text = "%d / %d" % [lit, total_crystals]
	_crystals_label.label_settings.font_color = UI.SUCCESS if lit == total_crystals else UI.TEXT_DIM
	_gems.set_counts(lit, total_crystals)


func set_music_state(enabled: bool) -> void:
	_music_button.text = "Música: ligada" if enabled else "Música: desligada"


# O main.gd escolhe onde o aviso atrapalha menos (canto com menos pecas do puzzle).
func set_toast_anchor(anchor: Vector2) -> void:
	_toast_anchor = anchor


# mood: "neutral", "happy", "thinking" ou "surprised" (muda a expressao do Echo).
# O texto aparece letra por letra, com um som curto de "fala".
func show_toast(title: String, text: String, duration := 6.0, mood := "neutral") -> void:
	_toast_title.text = title
	_toast_label.text = text
	_toast_icon.mood = mood
	_toast_icon.talking = true
	set_buddy_mood(mood, clampf(text.length() * 0.022, 0.2, 2.2) + 1.5)
	_buddy.talking = true
	_typing = true
	_typed_chars = 0
	_toast_label.visible_characters = 0
	var typing_time := clampf(text.length() * 0.022, 0.2, 2.2)
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_holder.visible = true
	_toast_holder.modulate.a = 0.0
	_toast_holder.position = _toast_anchor - Vector2(0, 14)
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast_holder, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_property(_toast_holder, "position:y", _toast_anchor.y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_property(_toast_label, "visible_characters", text.length(), typing_time)
	_toast_tween.chain().tween_callback(_finish_typing)
	_toast_tween.chain().tween_interval(duration)
	_toast_tween.chain().tween_property(_toast_holder, "modulate:a", 0.0, 0.5)
	_toast_tween.chain().tween_callback(func() -> void: _toast_holder.visible = false)


func hide_toast() -> void:
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_holder.visible = false
	_finish_typing()


func is_toast_visible() -> bool:
	return _toast_holder.visible


func _finish_typing() -> void:
	_typing = false
	_toast_label.visible_characters = -1
	if _toast_icon != null:
		_toast_icon.talking = false
	if _buddy != null:
		_buddy.talking = false


# Caixa de informacao que aparece ao passar o mouse sobre uma peca do puzzle.
func show_tooltip(title: String, body: String, screen_position: Vector2) -> void:
	_tooltip_title.text = title
	_tooltip_body.text = body
	_tooltip.visible = true
	_tooltip.reset_size()
	var tooltip_size := _tooltip.size
	var position_t := screen_position + Vector2(20, 22)
	if position_t.x + tooltip_size.x > 1268.0:
		position_t.x = screen_position.x - tooltip_size.x - 14.0
	if position_t.y + tooltip_size.y > 690.0:
		position_t.y = screen_position.y - tooltip_size.y - 14.0
	_tooltip.position = position_t


func hide_tooltip() -> void:
	_tooltip.visible = false


# ---------------------------------------------------------------- Echo da barra superior

func set_buddy_mood(mood: String, hold := 2.5) -> void:
	_buddy.mood = mood
	_buddy_mood_until = Time.get_ticks_msec() / 1000.0 + hold


# Sem mexer em nada por um tempo, o Echo cochila. Ao voltar, ele acorda assustado.
func set_buddy_sleepy(value: bool) -> void:
	if value == _buddy_sleepy:
		return
	_buddy_sleepy = value
	if value:
		_buddy.mood = "sleepy"
	else:
		set_buddy_mood("surprised", 1.2)


# O Echo voa da barra superior ate um ponto da tela (ao lado do espelho da dica),
# fica ali um tempo e volta. A barra fica sem o Echo enquanto ele esta fora.
func echo_fly_to(point: Vector2, stay := 4.5) -> void:
	if _flyer_tween != null:
		_flyer_tween.kill()
	var home := _buddy.get_global_rect().get_center()
	var from := home if not _flyer.visible else _flyer.position + _flyer.size * 0.5
	_flyer.visible = true
	_flyer.mood = "happy"
	_buddy.modulate.a = 0.0
	_flyer_tween = create_tween()
	_flyer_tween.tween_method(_place_flyer.bind(from, point), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flyer_tween.tween_callback(func() -> void:
		_flyer.mood = "thinking"
		Sfx.play("hint", 1.3)
	)
	_flyer_tween.tween_interval(stay)
	_flyer_tween.tween_callback(func() -> void: _flyer.mood = "happy")
	_flyer_tween.tween_method(_place_flyer.bind(point, home), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_flyer_tween.tween_callback(echo_return)


# Volta na hora (troca de fase, vitoria).
func echo_return() -> void:
	if _flyer_tween != null:
		_flyer_tween.kill()
	_flyer.visible = false
	_buddy.modulate.a = 1.0


# Caminho em arco entre dois pontos, com um balanco leve.
func _place_flyer(t: float, from: Vector2, to: Vector2) -> void:
	var middle := from.lerp(to, 0.5) + Vector2(0, -90)
	var point := from.lerp(middle, t).lerp(middle.lerp(to, t), t)
	point.y += sin(t * PI * 3.0) * 6.0
	_flyer.position = point - _flyer.size * 0.5


func _update_buddy() -> void:
	if Time.get_ticks_msec() / 1000.0 < _buddy_mood_until:
		return
	_buddy.mood = "sleepy" if _buddy_sleepy else "neutral"


# ---------------------------------------------------------------- pergunta do Echo

# Mostra uma pergunta com botoes. A resposta chega pelo sinal choice_made.
# Teclas 1 a 4 tambem respondem (o main.gd encaminha para choose()).
func ask(tag: String, question: String, options: Array) -> void:
	hide_toast()
	_choice_tag = tag
	_choice_label.text = question
	for child in _choice_buttons.get_children():
		_choice_buttons.remove_child(child)
		child.queue_free()
	for i in range(options.size()):
		var button := UI.make_button("%d  %s" % [i + 1, options[i]], 16)
		button.pressed.connect(choose.bind(i))
		_choice_buttons.add_child(button)
	set_buddy_mood("thinking", 30.0)
	_choice_holder.visible = true
	# A pergunta e mais larga que o balao: nao pode sair da tela.
	var choice_x := minf(_toast_anchor.x, 1264.0 - CHOICE_WIDTH)
	_choice_holder.position = Vector2(choice_x, _toast_anchor.y - 14.0)
	_choice_holder.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_choice_holder, "modulate:a", 1.0, 0.2)
	tween.tween_property(_choice_holder, "position:y", _toast_anchor.y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if GameState.last_input_pad and _choice_buttons.get_child_count() > 0:
		(_choice_buttons.get_child(0) as Control).grab_focus.call_deferred()


func choose(index: int) -> void:
	if not _choice_holder.visible or index < 0 or index >= _choice_buttons.get_child_count():
		return
	var tag := _choice_tag
	hide_choice()
	choice_made.emit(tag, index)


func hide_choice() -> void:
	if _choice_holder.visible:
		_buddy_mood_until = 0.0
	_choice_holder.visible = false
	_choice_tag = ""
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _choice_buttons.is_ancestor_of(focused):
		focused.release_focus()


func is_choice_open() -> bool:
	return _choice_holder.visible


func choice_tag() -> String:
	return _choice_tag


func choice_count() -> int:
	return _choice_buttons.get_child_count()


func _process(delta: float) -> void:
	_update_buddy()
	# Som curto de "fala" enquanto o texto do Echo e digitado.
	if _typing and _toast_label.visible_characters - _typed_chars >= 3:
		_typed_chars = _toast_label.visible_characters
		Sfx.play("talk", randf_range(0.9, 1.15))

	# A linha de ajuda mostra os comandos do controle quando ele esta sendo usado.
	var pad_mode: bool = GameState.last_input_pad and Input.get_connected_joypads().size() > 0
	if _help_label != null and pad_mode != _help_pad_mode:
		_help_pad_mode = pad_mode
		_help_label.text = HELP_PAD if pad_mode else _help_mouse

	# O aviso fica quase transparente quando o mouse passa por cima, para nao esconder o puzzle.
	if _toast_holder == null or not _toast_holder.visible:
		return
	var over := Rect2(_toast_holder.position, _toast.size).grow(12.0).has_point(_toast_holder.get_global_mouse_position())
	_toast.modulate.a = move_toward(_toast.modulate.a, 0.18 if over else 1.0, delta * 5.0)


func flash(strength := 0.55) -> void:
	if GameState.reduce_effects:
		return
	_flash.color.a = strength
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.6).set_ease(Tween.EASE_OUT)


# Vitoria: um fragmento brilhante sai do ultimo cristal (posicao na tela) e voa ate o
# logo do prisma no canto. Retorna o tempo do voo, para o painel esperar.
func fly_fragment(from: Vector2, color: Color) -> float:
	var flight := 0.8
	var shard := FragmentFly.new()
	shard.color = color
	shard.start = from
	shard.target = _logo.get_global_rect().get_center()
	add_child(shard)
	var tween := shard.create_tween()
	tween.tween_property(shard, "progress", 1.0, flight).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		_logo.pulse()
		Sfx.play("select", 1.5)
		shard.queue_free()
	)
	return flight


func show_victory(result: Dictionary, rotations: int, par: int, is_last: bool, seconds: float, echo_comment := "", explanation := "", story_index := -1) -> void:
	hide_toast()
	hide_choice()
	hide_tooltip()
	set_buddy_mood("happy", 6.0)
	_show_story(story_index)
	_victory_echo.text = echo_comment
	_victory_echo.get_parent().visible = echo_comment != ""
	_victory_echo_icon.mood = "happy"
	_why_label.text = explanation
	_why_label.visible = false
	_why_button.visible = explanation != ""
	_why_button.text = "Por que funcionou?  ▾"
	var earned: int = result["stars"]
	var whole_seconds := int(seconds)
	var fragments := GameState.completed_levels()
	var total := GameState.level_count()
	if is_last and fragments == total:
		_victory_title.text = "Prisma restaurado!"
	elif bool(result.get("first_clear", false)):
		_victory_title.text = "Fragmento %d de %d recuperado!" % [fragments, total]
	else:
		_victory_title.text = "Cristal ativado!"
	_victory_info.text = "Rotações: %d   ·   Meta ★★★: %d   ·   Tempo: %d:%02d" % [rotations, par, whole_seconds / 60, whole_seconds % 60]
	_victory_record.visible = bool(result["record"])
	_next_button.text = "Finalizar  ›" if is_last else "Próxima fase  ›"
	_victory_stars.count = earned
	_victory_stars.reveal = 0.0

	_victory_root.visible = true
	_victory_root.modulate.a = 0.0
	_victory_card.scale = Vector2(0.85, 0.85)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_victory_root, "modulate:a", 1.0, 0.3)
	tween.tween_property(_victory_card, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(0.15)
	for i in range(3):
		tween.chain().tween_property(_victory_stars, "reveal", float(i + 1), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < earned:
			tween.parallel().tween_callback(Sfx.play.bind("select", 1.0 + i * 0.2))
	tween.chain().tween_callback(_focus_if_pad.bind(_next_button))


func hide_victory() -> void:
	_victory_root.visible = false


# Memoria do fragmento: aparece na vitoria quando a fase e concluida pela primeira vez.
func _show_story(index: int) -> void:
	var fragment := Historia.fragmento(index)
	_story_box.visible = not fragment.is_empty()
	if fragment.is_empty():
		return
	_story_title.text = "MEMÓRIA %d DE %d  ·  %s" % [index + 1, Historia.total(), fragment["titulo"]]
	_story_text.text = fragment["texto"]
	var texture := Historia.imagem(index)
	_story_image.texture = texture
	_story_image.visible = texture != null


func show_pause(value: bool) -> void:
	_pause_root.visible = value
	if value:
		_focus_if_pad(_resume_button)


func _focus_if_pad(control: Control) -> void:
	# Com teclado/controle o botao principal ja vem focado; com mouse nada muda.
	if GameState.last_input_pad and control.is_visible_in_tree():
		control.grab_focus()


# ---------------------------------------------------------------- construcao

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	var style := UI.panel_style(Color(0.02, 0.035, 0.07, 0.94), Color(0.4, 0.7, 1.0, 0.35), 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 1
	style.content_margin_left = 24
	style.content_margin_right = 20
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", style)
	bar.position = Vector2.ZERO
	bar.size = Vector2(1280, 84)
	bar.custom_minimum_size = Vector2(1280, 84)
	add_child(bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)

	_logo = PrismLogo.new()
	row.add_child(_logo)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	_level_title = UI.make_label("Fase", 22, Color(1.0, 0.96, 0.84), 700)
	_level_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_objective = UI.make_label("Objetivo", 15, UI.TEXT_DIM, 500)
	# Objetivo longo quebra em ate 2 linhas em vez de empurrar os botoes para fora da tela.
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.max_lines_visible = 2
	_objective.custom_minimum_size.x = 200
	info.add_child(_level_title)
	info.add_child(_objective)

	var stats := VBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 0)
	stats.custom_minimum_size.x = 200
	row.add_child(stats)

	_rotations_label = UI.make_label("Rotações: 0", 18, UI.TEXT, 700)
	_goal_label = UI.make_label("Meta", 14, UI.ACCENT, 500)
	for label in [_rotations_label, _goal_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats.add_child(label)

	# Cristais como gemas que acendem (o numero fica ao lado, para quem preferir ler).
	var crystal_row := HBoxContainer.new()
	crystal_row.alignment = BoxContainer.ALIGNMENT_END
	crystal_row.add_theme_constant_override("separation", 6)
	stats.add_child(crystal_row)
	_gems = GemRow.new()
	crystal_row.add_child(_gems)
	_crystals_label = UI.make_label("Cristais: 0 / 1", 14, UI.TEXT_DIM, 600)
	crystal_row.add_child(_crystals_label)

	_buddy = EchoFace.new(19.0)
	_buddy.mouse_filter = Control.MOUSE_FILTER_STOP
	_buddy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_buddy.tooltip_text = "Converse com o Echo (T)"
	_buddy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_buddy.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			echo_clicked.emit()
	)
	row.add_child(_buddy)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	row.add_child(buttons)

	var hint_button := UI.make_button("Dica (H)", 15)
	hint_button.pressed.connect(func() -> void: hint_requested.emit())
	var restart_button := UI.make_button("Reiniciar (R)", 15)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	var pause_button := UI.make_button("II", 15)
	pause_button.tooltip_text = "Pausa (Esc)"
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	for button in [hint_button, restart_button, pause_button]:
		# Sem foco: setas e Espaco continuam controlando os espelhos, nao estes botoes.
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buttons.add_child(button)


func _build_bottom_help() -> void:
	_help_mouse = help_for_level(0)
	_help_label = UI.make_label(_help_mouse, 13,Color(0.55, 0.68, 0.85, 0.85), 500)
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.position = Vector2(0, 697)
	_help_label.size = Vector2(1280, 20)
	add_child(_help_label)


func _build_toast() -> void:
	_toast_holder = Control.new()
	_toast_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_holder.position = _toast_anchor
	_toast_holder.visible = false
	add_child(_toast_holder)

	_toast = UI.make_panel(Color(0.04, 0.08, 0.15, 0.95), Color(0.55, 0.85, 1.0, 0.6), 14, 14)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.custom_minimum_size = Vector2(TOAST_WIDTH, 0)
	_toast.size = Vector2(TOAST_WIDTH, 0)
	_toast_holder.add_child(_toast)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(row)

	_toast_icon = EchoFace.new()
	row.add_child(_toast_icon)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	_toast_title = UI.make_label("ECHO", 14, Color(0.55, 0.9, 1.0), 800)
	_toast_label = UI.make_label("", 17, UI.TEXT, 500)
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size.x = TOAST_WIDTH - 100.0
	# O tamanho do balao considera o texto inteiro, entao ele nao muda durante a digitacao.
	_toast_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	column.add_child(_toast_title)
	column.add_child(_toast_label)


func _build_choice() -> void:
	_choice_holder = Control.new()
	_choice_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_holder.visible = false
	add_child(_choice_holder)

	var panel := UI.make_panel(Color(0.04, 0.08, 0.15, 0.97), Color(1.0, 0.86, 0.36, 0.7), 14, 14)
	panel.custom_minimum_size = Vector2(CHOICE_WIDTH, 0)
	_choice_holder.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var face := EchoFace.new()
	face.mood = "thinking"
	row.add_child(face)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)
	column.add_child(UI.make_label("ECHO PERGUNTA", 14, UI.ACCENT, 800))
	_choice_label = UI.make_label("", 17, UI.TEXT, 500)
	_choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_choice_label.custom_minimum_size.x = 540
	column.add_child(_choice_label)
	_choice_buttons = HBoxContainer.new()
	_choice_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_choice_buttons)


func _build_tooltip() -> void:
	_tooltip = UI.make_panel(Color(0.03, 0.06, 0.12, 0.96), Color(1.0, 0.86, 0.36, 0.6), 10, 10)
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	add_child(_tooltip)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(column)
	_tooltip_title = UI.make_label("", 15, UI.ACCENT, 800)
	_tooltip_body = UI.make_label("", 14, UI.TEXT, 500)
	_tooltip_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_body.custom_minimum_size.x = 290
	column.add_child(_tooltip_title)
	column.add_child(_tooltip_body)


func _toggle_explanation() -> void:
	_why_label.visible = not _why_label.visible
	_why_button.text = "Esconder explicação  ▴" if _why_label.visible else "Por que funcionou?  ▾"


func _build_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.position = Vector2(0, 300)
	_banner.size = Vector2(1280, 120)
	_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	add_child(_banner)

	_banner_title = UI.make_label("FASE 1", 22, Color(0.6, 0.85, 1.0), 800, 6)
	_banner_name = UI.make_label("", 52, Color(1.0, 0.97, 0.88), 800, 10)
	for label in [_banner_title, _banner_name]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.add_child(label)


func _show_banner(title: String, level_name: String) -> void:
	_banner_title.text = title
	_banner_name.text = level_name
	_banner.modulate.a = 0.0
	_banner.position.y = 320.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_banner, "modulate:a", 1.0, 0.35)
	tween.tween_property(_banner, "position:y", 290.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(1.0)
	tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.45)


func _build_flash() -> void:
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.98, 0.9, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


func _make_overlay(shade_alpha: float) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.03, shade_alpha)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	return root


func _build_victory() -> void:
	_victory_root = _make_overlay(0.55)
	var center: CenterContainer = _victory_root.get_child(1)

	_victory_card = UI.make_panel(Color(0.035, 0.06, 0.11, 0.97), Color(0.5, 1.0, 0.7, 0.55), 18, 28)
	_victory_card.custom_minimum_size = Vector2(560, 0)
	_victory_card.resized.connect(func() -> void: _victory_card.pivot_offset = _victory_card.size * 0.5)
	center.add_child(_victory_card)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	_victory_card.add_child(column)

	_victory_title = UI.make_label("Cristal ativado!", 36, Color(0.62, 1.0, 0.74), 800, 8)
	_victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_victory_title)

	_victory_stars = StarRow.new()
	_victory_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_victory_stars)

	_victory_info = UI.make_label("", 19, UI.TEXT, 600)
	_victory_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_victory_info)

	_victory_record = UI.make_label("Novo recorde pessoal!", 16, UI.ACCENT, 700)
	_victory_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_victory_record)

	var echo_row := HBoxContainer.new()
	echo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	echo_row.add_theme_constant_override("separation", 10)
	column.add_child(echo_row)
	_victory_echo_icon = EchoFace.new()
	echo_row.add_child(_victory_echo_icon)
	_victory_echo = UI.make_label("", 17, Color(0.75, 0.95, 1.0), 600)
	_victory_echo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_victory_echo.custom_minimum_size.x = 420
	_victory_echo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	echo_row.add_child(_victory_echo)

	_story_box = UI.make_panel(Color(0.08, 0.07, 0.16, 0.9), Color(0.78, 0.66, 1.0, 0.55), 10, 12)
	_story_box.visible = false
	column.add_child(_story_box)
	var story_row := HBoxContainer.new()
	story_row.add_theme_constant_override("separation", 12)
	_story_box.add_child(story_row)
	_story_image = TextureRect.new()
	_story_image.custom_minimum_size = Vector2(150, 100)
	_story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_story_image.visible = false
	story_row.add_child(_story_image)
	var story_column := VBoxContainer.new()
	story_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_column.add_theme_constant_override("separation", 4)
	story_row.add_child(story_column)
	_story_title = UI.make_label("", 13, Color(0.85, 0.75, 1.0), 800)
	_story_text = UI.make_label("", 15, Color(0.92, 0.9, 1.0), 500)
	_story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_text.custom_minimum_size.x = 340
	story_column.add_child(_story_title)
	story_column.add_child(_story_text)

	_why_button = UI.make_button("Por que funcionou?  ▾", 16)
	_why_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_why_button.pressed.connect(_toggle_explanation)
	column.add_child(_why_button)

	_why_label = UI.make_label("", 15, UI.TEXT, 500)
	_why_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_why_label.custom_minimum_size.x = 520
	_why_label.visible = false
	column.add_child(_why_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)

	var levels_button := UI.make_button("Fases", 18)
	levels_button.pressed.connect(func() -> void: level_select_requested.emit())
	var retry_button := UI.make_button("Jogar de novo", 18)
	retry_button.pressed.connect(func() -> void: restart_requested.emit())
	_next_button = UI.make_button("Próxima fase  ›", 18, 190)
	_next_button.pressed.connect(func() -> void: next_requested.emit())
	_next_button.add_to_group("default_focus")
	for button in [levels_button, retry_button, _next_button]:
		buttons.add_child(button)

	var keys := UI.make_label("N / Enter: continuar   ·   R: jogar de novo", 13, UI.TEXT_DIM, 500)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(keys)


func _build_pause() -> void:
	_pause_root = _make_overlay(0.65)
	var center: CenterContainer = _pause_root.get_child(1)

	var card := UI.make_panel(Color(0.035, 0.06, 0.11, 0.97), UI.PANEL_BORDER, 18, 28)
	card.custom_minimum_size = Vector2(380, 0)
	center.add_child(card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)

	var title := UI.make_label("Pausa", 36, Color(1.0, 0.96, 0.84), 800, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var resume := UI.make_button("Continuar", 20)
	resume.pressed.connect(func() -> void: resume_requested.emit())
	resume.add_to_group("default_focus")
	_resume_button = resume
	var restart := UI.make_button("Reiniciar fase", 20)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	_music_button = UI.make_button("Música: ligada", 20)
	_music_button.pressed.connect(func() -> void: music_toggled.emit())
	var levels_button := UI.make_button("Seleção de fases", 20)
	levels_button.pressed.connect(func() -> void: level_select_requested.emit())
	var menu := UI.make_button("Menu principal", 20)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	for button in [resume, restart, _music_button, levels_button, menu]:
		column.add_child(button)


# ---------------------------------------------------------------- widgets desenhados

class StarRow extends Control:
	const Kit := preload("res://scripts/ui_kit.gd")

	var count := 0
	var reveal := 0.0:
		set(value):
			reveal = value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(240, 76)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in range(3):
			var center := Vector2(size.x * 0.5 + (i - 1) * 76.0, size.y * 0.5 + (0.0 if i == 1 else 6.0))
			var base_radius := 30.0 if i == 1 else 25.0
			Kit.draw_star(self, center, base_radius, false)
			var amount := clampf(reveal - i, 0.0, 1.25)
			if i < count and amount > 0.0:
				Kit.draw_star(self, center, base_radius * amount, true)


# Uma gema por cristal da fase: apagada fica escura, acesa brilha e da um pulo.
class GemRow extends Control:
	var lit := 0
	var total := 1
	var _time := 0.0
	var _pop: Array = []

	func _init() -> void:
		custom_minimum_size = Vector2(20, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_counts(lit_count: int, total_count: int) -> void:
		if total_count != total:
			_pop.clear()
		for i in range(total_count):
			if _pop.size() <= i:
				_pop.append(0.0)
			if i < lit_count and i >= lit:
				_pop[i] = 1.0
		lit = lit_count
		total = total_count
		custom_minimum_size.x = maxf(20.0, total * 20.0)

	func _process(delta: float) -> void:
		_time += delta
		for i in range(_pop.size()):
			_pop[i] = maxf(0.0, float(_pop[i]) - delta * 2.5)
		queue_redraw()

	func _draw() -> void:
		for i in range(total):
			var on := i < lit
			var pop: float = _pop[i] if i < _pop.size() else 0.0
			var center := Vector2(10.0 + i * 20.0, size.y * 0.5 - pop * 4.0)
			var k := 1.0 + pop * 0.35
			var points := PackedVector2Array([
				center + Vector2(0, -8) * k, center + Vector2(6, 0) * k,
				center + Vector2(0, 8) * k, center + Vector2(-6, 0) * k,
			])
			if on:
				var shine := 0.5 + 0.5 * sin(_time * 3.0 + i)
				draw_circle(center, 10.0 * k, Color(0.5, 1.0, 0.75, 0.12 + 0.1 * shine))
				draw_colored_polygon(points, Color(0.55, 1.0, 0.78))
				draw_line(center + Vector2(-2, -4) * k, center + Vector2(1, -6) * k, Color(1, 1, 1, 0.9), 1.5, true)
			else:
				draw_colored_polygon(points, Color(0.1, 0.15, 0.24))
			points.append(points[0])
			draw_polyline(points, Color(0.75, 1.0, 0.85) if on else Color(0.4, 0.5, 0.65), 1.2, true)


# Fragmento do prisma voando do cristal ate o logo, em curva, deixando um rastro.
class FragmentFly extends Node2D:
	var start := Vector2.ZERO
	var target := Vector2.ZERO
	var color := Color.WHITE
	var progress := 0.0:
		set(value):
			progress = value
			queue_redraw()

	func _point(t: float) -> Vector2:
		# Curva para cima, como uma faisca subindo.
		var control := start.lerp(target, 0.5) + Vector2(0, -160)
		return start.lerp(control, t).lerp(control.lerp(target, t), t)

	func _draw() -> void:
		for i in range(10):
			var t := maxf(0.0, progress - i * 0.025)
			var fade := 1.0 - i / 10.0
			draw_circle(_point(t), 10.0 * fade, Color(color.r, color.g, color.b, 0.18 * fade))
		var head := _point(progress)
		var spin := progress * TAU * 1.5
		var k := 1.0 + sin(progress * PI) * 0.6
		var points := PackedVector2Array()
		for corner in [Vector2(0, -11), Vector2(7, 0), Vector2(0, 11), Vector2(-7, 0)]:
			points.append(head + corner.rotated(spin) * k)
		draw_circle(head, 20.0 * k, Color(color.r, color.g, color.b, 0.22))
		draw_colored_polygon(points, color.lerp(Color.WHITE, 0.45))
		points.append(points[0])
		draw_polyline(points, Color.WHITE, 1.5, true)


class PrismLogo extends Control:
	var _time := 0.0
	var _pulse := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(56, 60)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	# O fragmento chegou: o prisma do logo brilha.
	func pulse() -> void:
		_pulse = 1.0

	func _process(delta: float) -> void:
		_time += delta
		_pulse = maxf(0.0, _pulse - delta * 1.5)
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		if _pulse > 0.0:
			draw_circle(c, 30.0 + 14.0 * (1.0 - _pulse), Color(1.0, 0.95, 0.7, 0.35 * _pulse))
		var top := c + Vector2(0, -22)
		var right := c + Vector2(22, 17)
		var left := c + Vector2(-22, 17)
		draw_colored_polygon(PackedVector2Array([top, right, left]), Color(0.2, 0.18, 0.4, 0.8))
		draw_polyline(PackedVector2Array([top, right, left, top]), Color(0.7, 0.75, 1.0), 2.0, true)
		var colors := [Color(1.0, 0.35, 0.4), Color(0.4, 1.0, 0.55), Color(0.4, 0.65, 1.0)]
		for i in range(3):
			var alpha := 0.6 + 0.4 * sin(_time * 2.0 + i)
			var col: Color = colors[i]
			draw_line(c + Vector2(4, 0), c + Vector2(28, -8 + i * 8), Color(col.r, col.g, col.b, alpha), 2.0, true)
		draw_line(c + Vector2(-30, 2), c + Vector2(-6, 2), Color(1.0, 0.93, 0.6), 2.0, true)
