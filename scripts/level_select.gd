extends Node2D

# Selecao de fases como o Farol de Aurora: as 10 fases sao andares, de baixo para cima,
# que acendem conforme sao concluidas. Ao lado, o cartao da fase escolhida com a miniatura.
# Mouse: passar por um andar mostra a fase; clicar joga. Teclado/controle: cima/baixo e Enter.

const UI := preload("res://scripts/ui_kit.gd")

@onready var hud: CanvasLayer = $HUD

var _tower: Lighthouse
var _preview: RoomPreview
var _name_label: Label
var _objective_label: Label
var _goal_label: Label
var _record_label: Label
var _stars: StarsRow
var _play_button: Button
var _selected := 0


func _ready() -> void:
	get_tree().paused = false
	Sfx.play_music("res://assets/audio/menu_loop.mp3", -10.0)

	var title := UI.make_label("O Farol de Aurora", 40, Color(1.0, 0.96, 0.86), 800, 8)
	title.position = Vector2(500, 40)
	hud.add_child(title)

	var total := GameState.level_count()
	var summary := UI.make_label("◆ %d / %d fragmentos     ★ %d / %d" % [GameState.completed_levels(), total, GameState.total_stars(), total * 3], 20, UI.ACCENT, 800, 4)
	summary.position = Vector2(502, 96)
	hud.add_child(summary)

	_tower = Lighthouse.new()
	_tower.position = Vector2(60, 20)
	_tower.size = Vector2(400, 690)
	_tower.floor_hovered.connect(_select_level)
	_tower.floor_pressed.connect(_on_floor_pressed)
	hud.add_child(_tower)

	_build_detail_card()

	var back := UI.make_button("‹  Voltar ao menu", 18)
	back.position = Vector2(500, 640)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: Transition.go_to("res://scenes/menu.tscn"))
	hud.add_child(back)

	var tip := UI.make_label("Passe o mouse pelos andares   ·   ▲ ▼ escolhem   ·   Enter joga", 14, UI.TEXT_DIM, 500)
	tip.position = Vector2(730, 652)
	hud.add_child(tip)

	_select_level(_suggested_level(), false)

	# Entrada: a torre sobe do chao e o cartao aparece.
	_tower.modulate.a = 0.0
	_tower.position.y += 30.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_tower, "modulate:a", 1.0, 0.4)
	tween.tween_property(_tower, "position:y", 20.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _build_detail_card() -> void:
	var card := UI.make_panel(UI.PANEL_BG, UI.PANEL_BORDER, 16, 20)
	card.position = Vector2(500, 140)
	card.custom_minimum_size = Vector2(700, 0)
	hud.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)

	_preview = RoomPreview.new()
	_preview.custom_minimum_size = Vector2(660, 300)
	column.add_child(_preview)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	_name_label = UI.make_label("", 24, Color(1.0, 0.96, 0.84), 800)
	_objective_label = UI.make_label("", 15, UI.TEXT_DIM, 500)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size.x = 420
	_goal_label = UI.make_label("", 14, UI.ACCENT, 600)
	_record_label = UI.make_label("", 14, UI.SUCCESS, 600)
	for label in [_name_label, _objective_label, _goal_label, _record_label]:
		texts.add_child(label)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	_stars = StarsRow.new()
	_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right.add_child(_stars)
	_play_button = UI.make_button("Jogar  ›", 22, 180)
	# Sem foco: setas escolhem o andar e Enter joga (tratados em _input).
	_play_button.focus_mode = Control.FOCUS_NONE
	_play_button.pressed.connect(func() -> void: _on_floor_pressed(_selected))
	right.add_child(_play_button)


func _input(event: InputEvent) -> void:
	if Transition.is_busy():
		return
	var step := 0
	if event.is_action_pressed("ui_up"):
		step = 1
	elif event.is_action_pressed("ui_down"):
		step = -1
	if step != 0:
		var next := clampi(_selected + step, 0, GameState.level_count() - 1)
		if next != _selected:
			_select_level(next)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_floor_pressed(_selected)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Transition.go_to("res://scenes/menu.tscn")
		get_viewport().set_input_as_handled()


# Fase sugerida: a primeira liberada ainda nao concluida.
func _suggested_level() -> int:
	for index in range(GameState.level_count()):
		if GameState.is_unlocked(index) and GameState.stars[index] == 0:
			return index
	return 0


func _select_level(index: int, with_sound := true) -> void:
	if with_sound and index != _selected:
		Sfx.play("hover")
	_selected = index
	_tower.selected = index
	var level: Dictionary = GameState.levels[index]
	var unlocked := GameState.is_unlocked(index)
	var best: int = GameState.best_rotations[index]
	_preview.level = level
	_preview.unlocked = unlocked
	_preview.queue_redraw()
	_name_label.text = "Andar %d  ·  %s" % [index + 1, level["name"]]
	_objective_label.text = level["objective"] if unlocked else "Termine o andar de baixo para acender este."
	_goal_label.text = "Meta ★★★: até %d rotações" % int(level["par"])
	_record_label.text = "Recorde: %d rotações" % best if best >= 0 else ("Ainda não concluída" if unlocked else "Bloqueada")
	_record_label.label_settings.font_color = UI.SUCCESS if best >= 0 else UI.TEXT_DIM
	_stars.count = GameState.stars[index]
	_stars.queue_redraw()
	_play_button.disabled = not unlocked
	_play_button.text = ("Jogar de novo  ›" if best >= 0 else "Jogar  ›") if unlocked else "Bloqueada"


func _on_floor_pressed(index: int) -> void:
	if not GameState.is_unlocked(index):
		Sfx.play("locked")
		_tower.shake(index)
		return
	Sfx.play("select")
	GameState.current_level = index
	Transition.go_to("res://scenes/main.tscn")


# ---------------------------------------------------------------- farol

class Lighthouse extends Control:
	signal floor_hovered(index: int)
	signal floor_pressed(index: int)

	const Kit := preload("res://scripts/ui_kit.gd")
	const FLOOR_TOP := 186.0
	const FLOOR_BOTTOM := 640.0
	const TOP_HALF := 92.0
	const BOTTOM_HALF := 150.0

	var selected := 0
	var _time := 0.0
	var _hover := -1
	var _shake_floor := -1
	var _shake := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func shake(index: int) -> void:
		_shake_floor = index
		_shake = 1.0

	func _floor_count() -> int:
		return GameState.level_count()

	func _floor_height() -> float:
		return (FLOOR_BOTTOM - FLOOR_TOP) / _floor_count()

	# Largura da torre (metade) numa altura y: mais larga embaixo.
	func _half_at(y: float) -> float:
		var t := clampf((y - FLOOR_TOP) / (FLOOR_BOTTOM - FLOOR_TOP), 0.0, 1.0)
		return lerpf(TOP_HALF, BOTTOM_HALF, t)

	func _floor_at(point: Vector2) -> int:
		if point.y < FLOOR_TOP or point.y >= FLOOR_BOTTOM:
			return -1
		if absf(point.x - size.x * 0.5) > _half_at(point.y):
			return -1
		return _floor_count() - 1 - int((point.y - FLOOR_TOP) / _floor_height())

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var index := _floor_at(event.position)
			if index != _hover:
				_hover = index
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if index >= 0 else Control.CURSOR_ARROW
				if index >= 0:
					floor_hovered.emit(index)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var index := _floor_at(event.position)
			if index >= 0:
				floor_pressed.emit(index)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			_hover = -1

	func _process(delta: float) -> void:
		_time += delta
		_shake = maxf(0.0, _shake - delta * 3.0)
		queue_redraw()

	func _draw() -> void:
		var cx := size.x * 0.5
		var lit_ratio := float(GameState.completed_levels()) / maxf(1.0, float(_floor_count()))
		_draw_ground(cx)
		_draw_lantern(cx, lit_ratio)

		# Corpo da torre.
		var body := PackedVector2Array([
			Vector2(cx - TOP_HALF, FLOOR_TOP), Vector2(cx + TOP_HALF, FLOOR_TOP),
			Vector2(cx + BOTTOM_HALF, FLOOR_BOTTOM), Vector2(cx - BOTTOM_HALF, FLOOR_BOTTOM),
		])
		draw_colored_polygon(body, Color(0.05, 0.07, 0.12))

		for index in range(_floor_count()):
			_draw_floor(cx, index)

		body.append(body[0])
		draw_polyline(body, Color(0.42, 0.6, 0.9, 0.55), 2.0, true)

	func _draw_floor(cx: float, index: int) -> void:
		var height := _floor_height()
		var top := FLOOR_BOTTOM - (index + 1) * height
		var bottom := top + height
		var half_top := _half_at(top)
		var half_bottom := _half_at(bottom)
		var offset := 0.0
		if index == _shake_floor and _shake > 0.0:
			offset = sin(_time * 60.0) * 4.0 * _shake
		var band := PackedVector2Array([
			Vector2(cx - half_top + 2, top + 1), Vector2(cx + half_top - 2, top + 1),
			Vector2(cx + half_bottom - 2, bottom - 1), Vector2(cx - half_bottom + 2, bottom - 1),
		])
		var stars: int = GameState.stars[index]
		var unlocked := GameState.is_unlocked(index)
		var done := stars > 0
		var fill := Color(0.06, 0.08, 0.13)
		if done:
			fill = Color(0.2, 0.15, 0.07)
		elif unlocked:
			fill = Color(0.07, 0.12, 0.22)
		draw_colored_polygon(band, fill)
		if index == selected:
			var pulse := 0.5 + 0.5 * sin(_time * 4.0)
			draw_colored_polygon(band, Color(1.0, 0.86, 0.36, 0.08 + pulse * 0.06))
			var outline := band.duplicate()
			outline.append(band[0])
			draw_polyline(outline, Kit.ACCENT, 2.0, true)
		draw_line(Vector2(cx - half_bottom, bottom), Vector2(cx + half_bottom, bottom), Color(0.3, 0.42, 0.62, 0.5), 1.0)

		# Janela: acesa (dourada) se concluida, azul piscando se liberada, escura se bloqueada.
		var window := Rect2(Vector2(cx - 13 + offset, top + 8), Vector2(26, height - 16))
		var glow := Color(1.0, 0.82, 0.4)
		if done:
			draw_circle(window.get_center(), 26.0, Color(glow.r, glow.g, glow.b, 0.12))
			draw_rect(window, glow)
		elif unlocked:
			var blink := 0.55 + 0.45 * sin(_time * 3.0)
			draw_rect(window, Color(0.4, 0.7, 1.0, 0.35 + 0.35 * blink))
		else:
			draw_rect(window, Color(0.03, 0.04, 0.07))
		draw_rect(window, Color(0.5, 0.62, 0.8, 0.7), false, 1.5)
		draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), Color(0.1, 0.1, 0.15, 0.6), 1.0)

		# Numero a esquerda e estrelas a direita.
		var text_color := Kit.TEXT if unlocked else Color(0.4, 0.46, 0.56)
		draw_string(Kit.font(800), Vector2(cx - half_bottom + 14 + offset, top + height * 0.5 + 6), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, text_color)
		if unlocked:
			for i in range(3):
				Kit.draw_star(self, Vector2(cx + 34 + i * 15 + offset, top + height * 0.5), 6.0, i < stars)
		else:
			var lock := Vector2(cx + 52 + offset, top + height * 0.5)
			draw_arc(lock + Vector2(0, -3), 4.0, PI, TAU, 10, Color(0.45, 0.5, 0.6), 2.0, true)
			draw_rect(Rect2(lock + Vector2(-5, -3), Vector2(10, 8)), Color(0.45, 0.5, 0.6))

	# Sala da lanterna no topo, com o prisma. Brilha mais a cada fragmento recuperado.
	func _draw_lantern(cx: float, lit_ratio: float) -> void:
		var center := Vector2(cx, 128)
		if lit_ratio > 0.0:
			# Feixes girando: quanto mais fragmentos, mais fortes e longos.
			for i in range(2):
				var angle := _time * 0.6 + i * PI
				var direction := Vector2(cos(angle), sin(angle) * 0.25)
				var reach := 120.0 + 260.0 * lit_ratio
				var spread := direction.orthogonal() * (14.0 + 30.0 * lit_ratio)
				var beam := PackedVector2Array([center, center + direction * reach + spread, center + direction * reach - spread])
				draw_colored_polygon(beam, Color(1.0, 0.9, 0.55, 0.05 + 0.12 * lit_ratio))
			draw_circle(center, 40.0 + 30.0 * lit_ratio, Color(1.0, 0.85, 0.45, 0.06 + 0.12 * lit_ratio))
		# Cupula, vidro e grade.
		draw_colored_polygon(PackedVector2Array([center + Vector2(-52, -26), center + Vector2(0, -62), center + Vector2(52, -26)]), Color(0.12, 0.16, 0.26))
		draw_rect(Rect2(center + Vector2(-46, -26), Vector2(92, 58)), Color(0.08, 0.14, 0.24, 0.85))
		for x in [-23.0, 0.0, 23.0]:
			draw_line(center + Vector2(x, -26), center + Vector2(x, 32), Color(0.4, 0.55, 0.8, 0.5), 1.5)
		draw_rect(Rect2(center + Vector2(-46, -26), Vector2(92, 58)), Color(0.45, 0.62, 0.9, 0.8), false, 2.0)
		draw_rect(Rect2(center + Vector2(-64, 32), Vector2(128, 8)), Color(0.18, 0.24, 0.36))
		for i in range(9):
			var x := -60.0 + i * 15.0
			draw_line(center + Vector2(x, 32), center + Vector2(x, 20), Color(0.35, 0.45, 0.65), 1.5)
		draw_line(center + Vector2(-64, 20), center + Vector2(64, 20), Color(0.35, 0.45, 0.65), 1.5)
		# Prisma: o brilho cresce com os fragmentos.
		var prism := PackedVector2Array([center + Vector2(0, -16), center + Vector2(15, 12), center + Vector2(-15, 12)])
		draw_colored_polygon(prism, Color(0.3, 0.26, 0.55).lerp(Color(1.0, 0.95, 0.75), lit_ratio))
		prism.append(prism[0])
		draw_polyline(prism, Color(0.85, 0.85, 1.0), 2.0, true)

	# Rochas e o mar na base.
	func _draw_ground(cx: float) -> void:
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 200, 690), Vector2(cx - 170, FLOOR_BOTTOM), Vector2(cx + 170, FLOOR_BOTTOM), Vector2(cx + 200, 690),
		]), Color(0.06, 0.08, 0.11))
		for i in range(3):
			var y := 660.0 + i * 12.0
			var wave := PackedVector2Array()
			for k in range(21):
				var x := cx - 200 + k * 20.0
				wave.append(Vector2(x, y + sin(_time * 1.5 + k * 0.8 + i) * 3.0))
			draw_polyline(wave, Color(0.3, 0.5, 0.85, 0.25 - i * 0.06), 2.0, true)


# ---------------------------------------------------------------- cartao da fase

# Miniatura da sala no tamanho do controle.
class RoomPreview extends Control:
	const Kit := preload("res://scripts/ui_kit.gd")
	const ROOM := Rect2(40.0, 100.0, 1200.0, 590.0)

	var level: Dictionary = {}
	var unlocked := true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _scale() -> float:
		return minf(size.x / ROOM.size.x, size.y / ROOM.size.y)

	func _map(point: Vector2) -> Vector2:
		var k := _scale()
		var origin := (size - ROOM.size * k) * 0.5
		return origin + (point - ROOM.position) * k

	func _draw() -> void:
		if level.is_empty():
			return
		var k := _scale()
		var frame := Rect2(_map(ROOM.position), ROOM.size * k)
		draw_rect(frame, Color(0.02, 0.035, 0.07))
		var step := 60.0 * k
		var x := frame.position.x
		while x < frame.end.x:
			draw_line(Vector2(x, frame.position.y), Vector2(x, frame.end.y), Color(0.3, 0.5, 0.9, 0.06), 1.0)
			x += step
		draw_rect(frame, Color(0.4, 0.65, 1.0, 0.35), false, 1.5)

		for obstacle in level["obstacles"]:
			var block: Vector2 = obstacle["size"] * k
			draw_rect(Rect2(_map(obstacle["position"]) - block * 0.5, block), Color(0.8, 0.2, 0.28, 0.9))
		for color_filter in level["filters"]:
			var direction := Vector2.RIGHT.rotated(deg_to_rad(color_filter["rotation"])) * 50.0 * k
			var center := _map(color_filter["position"])
			draw_line(center - direction, center + direction, Kit.light_color(color_filter["color"]), 5.0)
		for prism in level.get("prisms", []):
			var center := _map(prism["position"])
			var outline := PackedVector2Array([center + Vector2(0, -12), center + Vector2(11, 8), center + Vector2(-11, 8), center + Vector2(0, -12)])
			draw_polyline(outline, Color(0.8, 0.8, 1.0), 2.0, true)
		for mirror in level["mirrors"]:
			var half := 60.0 if mirror["kind"] == "mirror" else 55.0
			var direction := Vector2.RIGHT.rotated(deg_to_rad(mirror["rotation"])) * half * k
			var center := _map(mirror["position"])
			var color := Color(0.85, 0.93, 1.0)
			if mirror["kind"] == "splitter":
				color = Color(0.78, 0.66, 1.0)
			elif not mirror["can_rotate"]:
				color = Color(0.55, 0.6, 0.68)
			draw_line(center - direction, center + direction, color, 3.0, true)
		for crystal in level["crystals"]:
			var center := _map(crystal["position"])
			var color := Kit.light_color(crystal["color"])
			draw_circle(center, 14.0 * k * 1.6, Color(color.r, color.g, color.b, 0.2))
			draw_circle(center, 7.0, color)
		var emitter := _map(level["emitter"]["position"])
		draw_colored_polygon(PackedVector2Array([emitter + Vector2(-7, -6), emitter + Vector2(-7, 6), emitter + Vector2(8, 0)]), Color(1.0, 0.75, 0.3))

		if not unlocked:
			draw_rect(frame, Color(0.0, 0.01, 0.03, 0.75))
			var lock := frame.get_center()
			draw_circle(lock, 34.0, Color(0.08, 0.1, 0.16, 0.95))
			draw_arc(lock + Vector2(0, -7), 10.0, PI, TAU, 16, Color(0.75, 0.8, 0.9), 4.0, true)
			draw_rect(Rect2(lock + Vector2(-14, -7), Vector2(28, 22)), Color(0.75, 0.8, 0.9))


class StarsRow extends Control:
	const Kit := preload("res://scripts/ui_kit.gd")
	var count := 0

	func _init() -> void:
		custom_minimum_size = Vector2(150, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in range(3):
			Kit.draw_star(self, Vector2(size.x * 0.5 + (i - 1) * 46.0, size.y * 0.5), 18.0, i < count)
