extends Node2D

# Tela de selecao de fases com miniatura de cada sala, estrelas, recorde e cadeado.

const UI := preload("res://scripts/ui_kit.gd")
const CARD_SIZE := Vector2(200, 204)
const COLUMNS := 5

@onready var hud: CanvasLayer = $HUD

var _cards: Array = []


func _ready() -> void:
	get_tree().paused = false
	Sfx.play_music("res://assets/audio/menu_loop.mp3", -10.0)

	var title := UI.make_label("Seleção de fases", 44, Color(1.0, 0.96, 0.86), 800, 8)
	title.position = Vector2(108, 40)
	hud.add_child(title)

	var total := GameState.level_count()
	var summary := UI.make_label("◆ %d / %d fragmentos     ★ %d / %d" % [GameState.completed_levels(), total, GameState.total_stars(), total * 3], 22, UI.ACCENT, 800, 4)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.position = Vector2(672, 54)
	summary.size = Vector2(500, 40)
	hud.add_child(summary)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 18)
	grid.position = Vector2(108, 124)
	hud.add_child(grid)

	for index in range(total):
		var button := Button.new()
		button.custom_minimum_size = CARD_SIZE
		button.focus_mode = Control.FOCUS_ALL
		button.focus_entered.connect(_on_card_hover.bind(index, true))
		button.focus_exited.connect(_on_card_hover.bind(index, false))
		button.pivot_offset = CARD_SIZE * 0.5
		button.pressed.connect(_on_card_pressed.bind(index))
		button.mouse_entered.connect(_on_card_hover.bind(index, true))
		button.mouse_exited.connect(_on_card_hover.bind(index, false))
		grid.add_child(button)

		var card := LevelCard.new()
		card.setup(index, GameState.levels[index], GameState.stars[index], GameState.best_rotations[index], GameState.is_unlocked(index))
		card.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_child(card)
		_cards.append(button)
		if index == _suggested_level():
			button.add_to_group("default_focus")

		# Entrada escalonada.
		button.modulate.a = 0.0
		var tween := button.create_tween()
		tween.tween_interval(0.04 * index)
		tween.tween_property(button, "modulate:a", 1.0, 0.3)

	var back := UI.make_button("‹  Voltar ao menu", 20)
	back.position = Vector2(108, 624)
	back.pressed.connect(func() -> void: Transition.go_to("res://scenes/menu.tscn"))
	hud.add_child(back)

	if GameState.last_input_pad:
		GameState.focus_default.call_deferred()

	var tip := UI.make_label("Termine uma fase para liberar a próxima. Refaça fases para conseguir ★★★.", 15, UI.TEXT_DIM, 500)
	tip.position = Vector2(420, 636)
	hud.add_child(tip)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Transition.go_to("res://scenes/menu.tscn")
		get_viewport().set_input_as_handled()


# Fase sugerida para o foco inicial: a primeira liberada ainda nao concluida.
func _suggested_level() -> int:
	for index in range(GameState.level_count()):
		if GameState.is_unlocked(index) and GameState.stars[index] == 0:
			return index
	return 0


func _on_card_pressed(index: int) -> void:
	var button: Button = _cards[index]
	if not GameState.is_unlocked(index):
		Sfx.play("locked")
		var tween := button.create_tween()
		for offset in [8.0, -8.0, 5.0, -5.0, 0.0]:
			tween.tween_property(button, "rotation", deg_to_rad(offset * 0.4), 0.04)
		return

	Sfx.play("select")
	GameState.current_level = index
	Transition.go_to("res://scenes/main.tscn")


func _on_card_hover(index: int, inside: bool) -> void:
	var button: Button = _cards[index]
	var unlocked := GameState.is_unlocked(index)
	if inside and unlocked:
		Sfx.play("hover")
	var tween := button.create_tween()
	var target := Vector2(1.05, 1.05) if inside and unlocked else Vector2.ONE
	tween.tween_property(button, "scale", target, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


class LevelCard extends Control:
	const Kit := preload("res://scripts/ui_kit.gd")
	const ROOM := Rect2(40.0, 100.0, 1200.0, 590.0)
	const PREVIEW := Rect2(10.0, 10.0, 180.0, 88.5)

	var index := 0
	var level: Dictionary = {}
	var stars := 0
	var best := -1
	var unlocked := false

	func setup(level_index: int, data: Dictionary, earned: int, best_rotations: int, is_unlocked: bool) -> void:
		index = level_index
		level = data
		stars = earned
		best = best_rotations
		unlocked = is_unlocked
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _to_preview(point: Vector2) -> Vector2:
		var scale_factor := PREVIEW.size.x / ROOM.size.x
		return PREVIEW.position + (point - ROOM.position) * scale_factor

	func _draw() -> void:
		var scale_factor := PREVIEW.size.x / ROOM.size.x

		# Miniatura da sala.
		draw_rect(PREVIEW, Color(0.02, 0.035, 0.07))
		draw_rect(PREVIEW, Color(0.4, 0.65, 1.0, 0.35), false, 1.0)

		for obstacle in level["obstacles"]:
			var block_size: Vector2 = obstacle["size"] * scale_factor
			draw_rect(Rect2(_to_preview(obstacle["position"]) - block_size * 0.5, block_size), Color(0.8, 0.2, 0.28, 0.9))

		for color_filter in level["filters"]:
			var direction := Vector2.RIGHT.rotated(deg_to_rad(color_filter["rotation"])) * 50.0 * scale_factor
			var center := _to_preview(color_filter["position"])
			draw_line(center - direction, center + direction, Kit.light_color(color_filter["color"]), 3.0)

		for prism in level.get("prisms", []):
			var center := _to_preview(prism["position"])
			var outline := PackedVector2Array([center + Vector2(0, -6), center + Vector2(5.5, 4), center + Vector2(-5.5, 4), center + Vector2(0, -6)])
			draw_polyline(outline, Color(0.8, 0.8, 1.0), 1.5, true)

		for mirror in level["mirrors"]:
			var half := 60.0 if mirror["kind"] == "mirror" else 55.0
			var direction := Vector2.RIGHT.rotated(deg_to_rad(mirror["rotation"])) * half * scale_factor
			var center := _to_preview(mirror["position"])
			var color := Color(0.85, 0.93, 1.0)
			if mirror["kind"] == "splitter":
				color = Color(0.78, 0.66, 1.0)
			elif not mirror["can_rotate"]:
				color = Color(0.55, 0.6, 0.68)
			draw_line(center - direction, center + direction, color, 2.0, true)

		for crystal in level["crystals"]:
			draw_circle(_to_preview(crystal["position"]), 4.0, Kit.light_color(crystal["color"]))

		var emitter_position := _to_preview(level["emitter"]["position"])
		draw_colored_polygon(PackedVector2Array([
			emitter_position + Vector2(-4, -3.5), emitter_position + Vector2(-4, 3.5), emitter_position + Vector2(4.5, 0),
		]), Color(1.0, 0.75, 0.3))

		# Numero, nome, meta e recorde.
		var bold := Kit.font(800)
		var regular := Kit.font(600)
		draw_circle(Vector2(25, 124), 15.0, Kit.ACCENT if stars == 3 else Color(0.12, 0.22, 0.36))
		draw_string(bold, Vector2(10, 130), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 30.0, 16, Color(0.1, 0.07, 0.02) if stars == 3 else Kit.TEXT)
		draw_string(regular, Vector2(48, 122), String(level["name"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 54.0, 15, Kit.TEXT)
		draw_string(regular, Vector2(48, 140), "Meta: %d rotações" % int(level["par"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 54.0, 12, Kit.TEXT_DIM)
		var record_text := "Recorde: %d" % best if best >= 0 else "Ainda não concluída"
		draw_string(regular, Vector2(12, 166), record_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 12, Kit.SUCCESS if best >= 0 else Kit.TEXT_DIM)

		for i in range(3):
			Kit.draw_star(self, Vector2(size.x * 0.5 - 22 + i * 22, 186), 8.5, i < stars)

		if not unlocked:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.01, 0.03, 0.72))
			# Cadeado e texto ficam dentro da miniatura, sem cobrir o nome da fase.
			var lock_center := Vector2(size.x * 0.5, 44)
			draw_circle(lock_center, 28.0, Color(0.08, 0.1, 0.16, 0.95))
			draw_arc(lock_center + Vector2(0, -6), 8.5, PI, TAU, 16, Color(0.75, 0.8, 0.9), 3.5, true)
			draw_rect(Rect2(lock_center + Vector2(-12, -6), Vector2(24, 19)), Color(0.75, 0.8, 0.9))
			draw_circle(lock_center + Vector2(0, 3), 3.0, Color(0.08, 0.1, 0.16))
			draw_string(regular, Vector2(0, 92), "Bloqueada", HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Kit.TEXT_DIM)
