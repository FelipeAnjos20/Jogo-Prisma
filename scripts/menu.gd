extends Node2D

# Menu principal: jogar/continuar, selecao de fases, como jogar, opcoes e sair.

const UI := preload("res://scripts/ui_kit.gd")

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
	var column := _new_column(380)
	_options_panel = column

	var card := UI.make_panel()
	column.add_child(card)
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

	_reset_button = UI.make_button("Apagar progresso", 17)
	_reset_button.pressed.connect(_on_reset_pressed)
	inner.add_child(_reset_button)

	var back := UI.make_button("Voltar", 20)
	back.pressed.connect(func() -> void: _show_panel(_main_panel))
	back.add_to_group("default_focus")
	column.add_child(back)


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
	_progress_label.position = Vector2(88, 648)
	hud.add_child(_progress_label)

	var version := UI.make_label("F11: tela cheia   ·   v3.0", 13, UI.TEXT_DIM, 500)
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
