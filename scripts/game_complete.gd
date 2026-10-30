extends Node2D

# Tela final: celebra a conclusao do jogo e mostra o total de estrelas.

const UI := preload("res://scripts/ui_kit.gd")

@onready var prism: Node2D = $Prism
@onready var title_label: Label = $HUD/TitleLabel
@onready var subtitle_label: Label = $HUD/SubtitleLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var confetti: Node2D = $HUD/CompletionConfetti
@onready var hud: CanvasLayer = $HUD

var time := 0.0
var _buttons: HBoxContainer


func _ready() -> void:
	get_tree().paused = false
	Sfx.play_music("res://assets/audio/gameplay_music.mp3", -16.0)
	Sfx.play("fanfare")

	var total := GameState.level_count()
	var earned := GameState.total_stars()
	prism.shard_count = total
	prism.shards_lit = total
	title_label.label_settings = UI.label_settings(64, Color(0.7, 1.0, 0.76), 800, 12)
	subtitle_label.label_settings = UI.label_settings(24, Color(0.92, 1.0, 0.95), 600, 5)
	hint_label.label_settings = UI.label_settings(14, UI.TEXT_DIM, 500)

	var stars_line := "★ %d de %d estrelas" % [earned, total * 3]
	if earned >= total * 3:
		stars_line += "  —  perfeito!"
	subtitle_label.text = "Você recuperou os %d fragmentos e restaurou o Prisma de Luz.\n%s" % [total, stars_line]

	_build_buttons(earned < total * 3)

	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	_buttons.modulate.a = 0.0
	title_label.scale = Vector2(0.72, 0.72)
	prism.scale = Vector2(0.6, 0.6)

	if confetti.has_method("play"):
		confetti.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(prism, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.35)
	tween.tween_property(title_label, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(subtitle_label, "modulate:a", 1.0, 0.45)
	tween.chain().tween_property(_buttons, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property(hint_label, "modulate:a", 1.0, 0.35)
	if GameState.last_input_pad:
		tween.chain().tween_callback(GameState.focus_default)


func _build_buttons(show_improve_tip: bool) -> void:
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 14)
	_buttons.position = Vector2(0, 586)
	_buttons.size = Vector2(1280, 56)
	hud.add_child(_buttons)

	var levels_button := UI.make_button("Seleção de fases", 20, 230)
	levels_button.pressed.connect(func() -> void: Transition.go_to("res://scenes/level_select.tscn"))
	var menu_button := UI.make_button("Menu principal", 20, 230)
	menu_button.pressed.connect(func() -> void: Transition.go_to("res://scenes/menu.tscn"))
	_buttons.add_child(levels_button)
	_buttons.add_child(menu_button)
	menu_button.add_to_group("default_focus")

	if show_improve_tip:
		hint_label.text = "Refaça fases com menos rotações para ganhar ★★★   ·   Enter: menu   ·   F: fases"


func _process(delta: float) -> void:
	time += delta
	prism.rotation = sin(time * 0.9) * 0.05


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Transition.go_to("res://scenes/menu.tscn")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			Transition.go_to("res://scenes/menu.tscn")
		elif event.keycode == KEY_F or event.keycode == KEY_R:
			Transition.go_to("res://scenes/level_select.tscn")
