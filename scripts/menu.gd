extends Node2D

# Menu principal: jogar/continuar, selecao de fases, memorias, como jogar, opcoes e sair.
# Na primeira partida o Echo pergunta o nome do jogador.

const UI := preload("res://scripts/ui_kit.gd")
const EchoFace := preload("res://scripts/echo_face.gd")
const Historia := preload("res://scripts/historia.gd")
const EchoBrain := preload("res://scripts/echo_brain.gd")

# Edite aqui os nomes da equipe para aparecerem na tela de creditos.
const TEAM := ["Vinicius Mesquita", "Felipe dos Anjos", "Eduardo Macedo", "Felipe Schwabe"]

@onready var hud: CanvasLayer = $HUD
@onready var art: Node2D = $Art

var _title: Label
var _subtitle: Label
var _main_panel: Control
var _options_panel: Control
var _howto_panel: Control
var _credits_panel: Control
var _name_panel: Control
var _memories_panel: Control
var _memories_list: VBoxContainer
var _name_input: LineEdit
var _options_name: LineEdit
var _panels: Array = []
var _reset_button: Button
var _reset_armed := false
var _progress_label: Label
var _play_button: Button
var _music_value: Label
var _sfx_value: Label


func _ready() -> void:
	get_tree().paused = false
	Sfx.play_music("res://assets/audio/menu_loop.mp3", -10.0)
	_build_header()
	_build_main_panel()
	_build_options_panel()
	_build_howto_panel()
	_build_credits_panel()
	_build_name_panel()
	_build_memories_panel()
	_build_footer()
	_refresh_progress()
	_show_panel(_main_panel)
	_play_intro()


func _unhandled_input(event: InputEvent) -> void:
	# Esc (teclado) ou B (controle) voltam para o painel principal.
	if event.is_action_pressed("ui_cancel") and not _main_panel.visible:
		_show_panel(_main_panel)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- construcao

func _build_header() -> void:
	_title = UI.make_label("PRISMA", 108, Color(0.9, 1.0, 0.96), 800, 14)
	_title.position = Vector2(78, 46)
	_title.size = Vector2(560, 140)
	hud.add_child(_title)

	_subtitle = UI.make_label("O lugar onde a luz quebrou", 23, Color(0.62, 0.8, 1.0), 600, 4)
	_subtitle.position = Vector2(88, 186)
	hud.add_child(_subtitle)

	var accent := ColorRect.new()
	accent.color = UI.ACCENT
	accent.position = Vector2(90, 226)
	accent.size = Vector2(120, 3)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(accent)


func _new_column(width: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.position = Vector2(86, 262)
	column.custom_minimum_size.x = width
	column.size.x = width
	column.add_theme_constant_override("separation", 12)
	hud.add_child(column)
	_panels.append(column)
	return column


func _build_main_panel() -> void:
	var column := _new_column(340)
	_main_panel = column

	_play_button = UI.make_button("Jogar", 24)
	_play_button.custom_minimum_size.y = 58
	_play_button.pressed.connect(_on_play)
	_play_button.add_to_group("default_focus")
	column.add_child(_play_button)

	var entries := [
		["Seleção de fases", func() -> void: Transition.go_to("res://scenes/level_select.tscn")],
		["Memórias do Prisma", func() -> void: _show_memories()],
		["Como jogar", func() -> void: _show_panel(_howto_panel)],
		["Opções", func() -> void: _show_panel(_options_panel)],
		["Créditos", func() -> void: _show_panel(_credits_panel)],
		["Sair", func() -> void: get_tree().quit()],
	]
	for entry in entries:
		var button := UI.make_button(entry[0], 20)
		button.pressed.connect(entry[1])
		column.add_child(button)


func _build_options_panel() -> void:
	var column := _new_column(800)
	_options_panel = column

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	column.add_child(cards)
	var card := UI.make_panel()
	card.custom_minimum_size.x = 380
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	card.add_child(inner)

	inner.add_child(UI.make_label("Opções", 28, Color(1.0, 0.96, 0.84), 800))

	_music_value = UI.make_label("", 16, UI.TEXT_DIM, 600)
	inner.add_child(_slider_row("Música", GameState.music_volume, _music_value, func(value: float) -> void:
		GameState.set_music_volume(value / 100.0)
		_music_value.text = "%d%%" % int(value)
	))

	_sfx_value = UI.make_label("", 16, UI.TEXT_DIM, 600)
	var sfx_row := _slider_row("Efeitos", GameState.sfx_volume, _sfx_value, func(value: float) -> void:
		GameState.set_sfx_volume(value / 100.0)
		_sfx_value.text = "%d%%" % int(value)
	)
	inner.add_child(sfx_row)
	var sfx_slider: HSlider = sfx_row.get_child(1)
	sfx_slider.drag_ended.connect(func(_changed: bool) -> void: Sfx.play("crystal_on"))

	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia (F11)"
	fullscreen.focus_mode = Control.FOCUS_ALL
	fullscreen.button_pressed = GameState.fullscreen
	fullscreen.toggled.connect(func(on: bool) -> void:
		GameState.set_fullscreen(on)
		Sfx.play("click")
	)
	inner.add_child(fullscreen)

	var angles := CheckButton.new()
	angles.text = "Mostrar ângulos e explicações (G)"
	angles.focus_mode = Control.FOCUS_ALL
	angles.button_pressed = GameState.show_angles
	angles.toggled.connect(func(on: bool) -> void:
		GameState.set_show_angles(on)
		Sfx.play("click")
	)
	inner.add_child(angles)

	# Segundo cartao: o jogador e o Echo.
	var echo_card := UI.make_panel()
	echo_card.custom_minimum_size.x = 380
	echo_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_child(echo_card)
	var echo_inner := VBoxContainer.new()
	echo_inner.add_theme_constant_override("separation", 12)
	echo_card.add_child(echo_inner)
	echo_inner.add_child(UI.make_label("Você e o Echo", 28, Color(1.0, 0.96, 0.84), 800))

	echo_inner.add_child(UI.make_label("Seu nome", 16, UI.TEXT_DIM, 600))
	_options_name = _make_name_input()
	_options_name.text = GameState.player_name
	_options_name.text_changed.connect(func(text: String) -> void: GameState.set_player_name(text))
	echo_inner.add_child(_options_name)

	var helper := CheckButton.new()
	helper.text = "Echo dá pistas quando eu travar"
	helper.focus_mode = Control.FOCUS_ALL
	helper.button_pressed = GameState.echo_help != "sozinho"
	helper.toggled.connect(func(on: bool) -> void:
		GameState.set_echo_help("ajuda" if on else "sozinho")
		Sfx.play("click")
	)
	echo_inner.add_child(helper)
	var helper_tip := UI.make_label("Desligado, o Echo só comemora e avisa o que acontece. Durante a fase, clique nele (ou T) para conversar.", 14, UI.TEXT_DIM, 500)
	helper_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	helper_tip.custom_minimum_size.x = 340
	echo_inner.add_child(helper_tip)

	_reset_button = UI.make_button("Apagar progresso", 17)
	_reset_button.pressed.connect(_on_reset_pressed)
	inner.add_child(_reset_button)

	var back := UI.make_button("Voltar", 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 200
	back.pressed.connect(func() -> void: _show_panel(_main_panel))
	back.add_to_group("default_focus")
	column.add_child(back)


func _make_name_input() -> LineEdit:
	var input := LineEdit.new()
	input.max_length = EchoBrain.NOME_MAX
	input.placeholder_text = "Digite seu nome"
	input.add_theme_font_override("font", UI.font(600))
	input.add_theme_font_size_override("font_size", 20)
	input.custom_minimum_size = Vector2(320, 46)
	return input


# Primeira partida: o Echo se apresenta e pergunta o nome do jogador.
func _build_name_panel() -> void:
	var column := _new_column(520)
	_name_panel = column

	var card := UI.make_panel(UI.PANEL_BG, Color(1.0, 0.86, 0.36, 0.6))
	column.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	card.add_child(inner)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	inner.add_child(row)
	var face := EchoFace.new(22.0)
	face.mood = "happy"
	row.add_child(face)
	var hello := UI.make_label("Oi! Eu sou Echo, o que sobrou da luz do Prisma. Vou te acompanhar nas salas. Como posso te chamar?", 18, UI.TEXT, 600)
	hello.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hello.custom_minimum_size.x = 390
	row.add_child(hello)

	_name_input = _make_name_input()
	_name_input.add_to_group("default_focus")
	_name_input.text_submitted.connect(func(_text: String) -> void: _confirm_name())
	inner.add_child(_name_input)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	inner.add_child(buttons)
	var start := UI.make_button("Começar  ›", 20, 200)
	start.pressed.connect(_confirm_name)
	var skip := UI.make_button("Prefiro não dizer", 17)
	skip.pressed.connect(func() -> void:
		GameState.set_player_name("")
		_start_game()
	)
	buttons.add_child(start)
	buttons.add_child(skip)


func _confirm_name() -> void:
	GameState.set_player_name(_name_input.text)
	if _options_name != null:
		_options_name.text = GameState.player_name
	_start_game()


# Memorias: a historia que cada fragmento recuperado conta.
func _build_memories_panel() -> void:
	var column := _new_column(780)
	_memories_panel = column

	var card := UI.make_panel(UI.PANEL_BG, Color(0.78, 0.66, 1.0, 0.5))
	column.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)
	inner.add_child(UI.make_label("Memórias do Prisma", 28, Color(1.0, 0.96, 0.84), 800))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(744, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.add_child(scroll)
	_memories_list = VBoxContainer.new()
	_memories_list.add_theme_constant_override("separation", 10)
	_memories_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_memories_list)

	var back := UI.make_button("Voltar", 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 200
	back.pressed.connect(func() -> void: _show_panel(_main_panel))
	back.add_to_group("default_focus")
	column.add_child(back)


func _show_memories() -> void:
	for child in _memories_list.get_children():
		_memories_list.remove_child(child)
		child.queue_free()
	for index in range(Historia.total()):
		var fragment := Historia.fragmento(index)
		var unlocked: bool = index < GameState.level_count() and GameState.stars[index] > 0
		var title := "%d.  %s" % [index + 1, fragment["titulo"] if unlocked else "Memória bloqueada"]
		_memories_list.add_child(UI.make_label(title, 17, Color(0.85, 0.75, 1.0) if unlocked else UI.TEXT_DIM, 800))
		var text := UI.make_label(fragment["texto"] if unlocked else "Conclua a fase %d para recuperar este fragmento." % (index + 1), 15, UI.TEXT if unlocked else UI.TEXT_DIM, 500)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = 720
		_memories_list.add_child(text)
	if GameState.completed_levels() >= Historia.total():
		var ending := UI.make_label(EchoBrain.personalizar(Historia.EPILOGO, GameState.player_name), 16, UI.ACCENT, 700)
		ending.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ending.custom_minimum_size.x = 720
		_memories_list.add_child(ending)
	_show_panel(_memories_panel)


func _slider_row(title: String, value: float, value_label: Label, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := UI.make_label(title, 18, UI.TEXT, 600)
	name_label.custom_minimum_size.x = 80
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value * 100.0
	slider.focus_mode = Control.FOCUS_ALL
	if title == "Música":
		slider.add_to_group("default_focus")
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	value_label.text = "%d%%" % int(value * 100.0)
	value_label.custom_minimum_size.x = 48
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return row


func _build_howto_panel() -> void:
	var column := _new_column(780)
	_howto_panel = column

	var card := UI.make_panel()
	column.add_child(card)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.custom_minimum_size = Vector2(744, 0)
	text.add_theme_color_override("default_color", UI.TEXT)
	text.add_theme_font_override("normal_font", UI.font(500))
	text.add_theme_font_override("bold_font", UI.font(800))
	text.add_theme_font_size_override("normal_font_size", 15)
	text.add_theme_font_size_override("bold_font_size", 17)
	text.text = "\n".join([
		"[b][color=#fff3c4]Objetivo[/color][/b]  Leve a luz do emissor até [b]todos[/b] os cristais ao mesmo tempo.",
		"",
		"[b][color=#fff3c4]Controles[/color][/b]",
		"•  [color=#ffe070]Clique[/color] para selecionar. [color=#ffe070]Arraste[/color] a ponta, use [color=#ffe070]Q/E[/color], a [color=#ffe070]roda do mouse[/color] ou [color=#ffe070]clique de novo[/color] para girar.",
		"•  [color=#ffe070]1-9[/color]/[color=#ffe070]Tab[/color] trocam   •  [color=#ffe070]Z[/color] desfaz   •  [color=#ffe070]R[/color] reinicia   •  [color=#ffe070]H[/color] dica (2x mostra o ângulo)   •  [color=#ffe070]Esc[/color] pausa",
		"",
		"[b][color=#fff3c4]Elementos[/color][/b]",
		"•  Espelho com [b]cadeado[/b]: reflete, mas não gira.   •  [color=#ff5a64]Bloco vermelho[/color]: absorve a luz.",
		"•  [color=#c8a8ff]Divisor roxo[/color]: parte da luz atravessa e parte é refletida.",
		"•  [color=#ff6070]Filtros[/color] [color=#60ff90]de[/color] [color=#6aa0ff]cor[/color]: tingem a luz branca. Luz colorida não passa por filtro de outra cor.",
		"•  [color=#d8d0ff]Prisma[/color]: separa a luz branca em [color=#ff6070]vermelho[/color], [color=#60ff90]verde[/color] e [color=#6aa0ff]azul[/color].",
		"•  Cristal com [b]anel colorido[/b]: só acende com aquela cor.",
		"•  Cores também têm forma: [color=#ff6070]▲ vermelho[/color]   [color=#60ff90]● verde[/color]   [color=#6aa0ff]■ azul[/color].",
		"",
		"[b][color=#fff3c4]Estrelas[/color][/b]  Quanto menos rotações, mais estrelas. ★★★ = bater a meta da fase.",
	])
	card.add_child(text)

	var back := UI.make_button("Voltar", 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 200
	back.pressed.connect(func() -> void: _show_panel(_main_panel))
	back.add_to_group("default_focus")
	column.add_child(back)


func _build_credits_panel() -> void:
	var column := _new_column(520)
	_credits_panel = column

	var card := UI.make_panel()
	column.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)

	inner.add_child(UI.make_label("Créditos", 28, Color(1.0, 0.96, 0.84), 800))
	inner.add_child(UI.make_label("PRISMA — O lugar onde a luz quebrou", 17, UI.ACCENT, 700))
	if not TEAM.is_empty():
		inner.add_child(UI.make_label("Equipe", 15, Color(0.6, 0.85, 1.0), 800))
		var team_grid := GridContainer.new()
		team_grid.columns = 2
		team_grid.add_theme_constant_override("h_separation", 28)
		for member in TEAM:
			team_grid.add_child(UI.make_label("•  " + member, 16, UI.TEXT, 600))
		inner.add_child(team_grid)
	var lines := [
		"PAC Extensionista III · Engenharia de Software · Católica SC",
		"Motor: Godot Engine 4.6 (licença MIT)",
		"Arte: gráficos vetoriais desenhados por código",
		"Efeitos sonoros: sintetizados por código",
		"Música: trilhas incluídas no projeto",
		"10 fases verificadas por simulador de feixe",
	]
	for line in lines:
		inner.add_child(UI.make_label(line, 16, UI.TEXT_DIM, 500))

	var back := UI.make_button("Voltar", 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 200
	back.pressed.connect(func() -> void: _show_panel(_main_panel))
	back.add_to_group("default_focus")
	column.add_child(back)


func _build_footer() -> void:
	_progress_label = UI.make_label("", 17, UI.ACCENT, 700)
	_progress_label.position = Vector2(88, 672)
	hud.add_child(_progress_label)

	var version := UI.make_label("F11: tela cheia   ·   v3.2", 13, UI.TEXT_DIM, 500)
	version.position = Vector2(1060, 690)
	hud.add_child(version)


# ---------------------------------------------------------------- acoes

func _refresh_progress() -> void:
	var total := GameState.level_count()
	var done := GameState.completed_levels()
	_progress_label.text = "★ %d / %d     ·     Fragmentos do prisma: %d / %d" % [GameState.total_stars(), total * 3, done, total]
	art.shards_lit = done
	art.shard_count = total

	if done == 0:
		_play_button.text = "Jogar"
	elif done >= total:
		_play_button.text = "Jogar novamente"
	else:
		_play_button.text = "Continuar  ·  Fase %d" % (_next_level() + 1)


func _next_level() -> int:
	for index in range(GameState.level_count()):
		if GameState.stars[index] == 0 and GameState.is_unlocked(index):
			return index
	return 0


func _on_play() -> void:
	if not GameState.name_asked:
		_show_panel(_name_panel)
		_name_input.grab_focus.call_deferred()
		return
	_start_game()


func _start_game() -> void:
	GameState.current_level = _next_level()
	Transition.go_to("res://scenes/main.tscn")


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Tem certeza? Clique para apagar"
		_reset_button.add_theme_color_override("font_color", UI.DANGER)
		return
	GameState.reset_progress()
	_reset_armed = false
	_reset_button.text = "Progresso apagado"
	_reset_button.remove_theme_color_override("font_color")
	_refresh_progress()


func _show_panel(panel: Control) -> void:
	_reset_armed = false
	if _reset_button != null:
		_reset_button.text = "Apagar progresso"
		_reset_button.remove_theme_color_override("font_color")

	for item in _panels:
		item.visible = item == panel
	if _progress_label != null:
		_progress_label.visible = panel == _main_panel
	# Com teclado/controle, o primeiro controle do painel ja vem focado.
	if GameState.last_input_pad:
		GameState.focus_default()
	panel.modulate.a = 0.0
	panel.position.x = 70.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "position:x", 86.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_intro() -> void:
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	art.modulate.a = 0.0
	art.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(art, "modulate:a", 1.0, 1.0)
	tween.tween_property(art, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title, "modulate:a", 1.0, 0.6).set_delay(0.15)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 0.6).set_delay(0.4)
