extends Node2D

# Espelho (reflete) ou divisor (reflete e deixa passar). Pode ser giravel ou travado.
# O feixe usa o segmento retornado por get_light_segment(); o desenho e todo feito por codigo.

signal rotated(mirror: Node2D, previous_degrees: float)

const UI := preload("res://scripts/ui_kit.gd")
const Geometria = preload("res://scripts/geometria.gd")

const MIRROR_LENGTH := 120.0
const SPLITTER_LENGTH := 110.0
const STEP_DEGREES := 15.0
const PICK_MARGIN := 18.0
const ROTATE_SPEED := 18.0

const SELECT_COLOR := Color(1.0, 0.84, 0.3)

var kind := "mirror"
var can_rotate := true
var target_degrees := 0.0
var number := 0
var is_selected := false
var is_hovered := false
var has_ghost := false
var ghost_degrees := 0.0

var _time := 0.0
var _flash := 0.0
var _shake := 0.0
# Balanco depois de cada giro (so visual: o feixe usa o angulo exato).
var _wobble := 0.0


func configure(data: Dictionary, key_number: int) -> void:
	kind = data["kind"]
	position = data["position"]
	target_degrees = Geometria.normalizar_angulo(data["rotation"])
	rotation_degrees = target_degrees
	can_rotate = data["can_rotate"]
	number = key_number
	_time = randf() * 10.0
	queue_redraw()


func is_splitter() -> bool:
	return kind == "splitter"


func half_length() -> float:
	return (SPLITTER_LENGTH if is_splitter() else MIRROR_LENGTH) * 0.5


func rotate_step(direction: int) -> bool:
	if not can_rotate:
		_shake = 1.0
		return false

	var previous := target_degrees
	# Regra do passo de 15 graus isolada e testada em Geometria (ver docs/adr/002).
	target_degrees = Geometria.proximo_angulo(target_degrees, direction, STEP_DEGREES)
	_flash = 1.0
	_wobble = 1.0
	rotated.emit(self, previous)
	return true


func restore_rotation(degrees: float) -> void:
	target_degrees = degrees
	_flash = 0.6
	_wobble = 0.7


func shake_locked() -> void:
	_shake = 1.0


# Dica: mostra um contorno pontilhado no angulo da solucao.
func show_ghost(degrees: float) -> void:
	ghost_degrees = degrees
	has_ghost = not matches_angle(degrees)


func matches_angle(degrees: float) -> bool:
	# Um espelho a 0 grau e a 180 graus e o mesmo espelho.
	return Geometria.mesma_orientacao_espelho(target_degrees, degrees)


func is_settled() -> bool:
	return absf(_degrees_to_target()) < 0.05


# Diferenca (em graus) pelo menor caminho entre o angulo desenhado e o angulo alvo.
func _degrees_to_target() -> float:
	return rad_to_deg(angle_difference(rotation, deg_to_rad(target_degrees)))


func set_selected(value: bool) -> void:
	is_selected = value


func set_hovered(value: bool) -> void:
	is_hovered = value


func contains_global_point(global_point: Vector2) -> bool:
	var local_point := to_local(global_point)
	return absf(local_point.x) <= half_length() + PICK_MARGIN * 0.5 and absf(local_point.y) <= PICK_MARGIN


func get_light_segment() -> PackedVector2Array:
	var half := half_length()
	return PackedVector2Array([to_global(Vector2(-half, 0.0)), to_global(Vector2(half, 0.0))])


func _process(delta: float) -> void:
	_time += delta

	# Gira suavemente pelo menor caminho (ex.: de 345 para 0 graus anda so 15).
	var difference := _degrees_to_target()
	if absf(difference) > 0.0:
		rotation_degrees += difference * minf(1.0, delta * ROTATE_SPEED)
		if absf(_degrees_to_target()) < 0.05:
			rotation_degrees = target_degrees

	if has_ghost and matches_angle(ghost_degrees):
		has_ghost = false
		_flash = 1.0

	_flash = maxf(0.0, _flash - delta * 3.0)
	_shake = maxf(0.0, _shake - delta * 3.5)
	_wobble = maxf(0.0, _wobble - delta * 2.2)
	queue_redraw()


func _draw() -> void:
	var half := half_length()
	var shake_offset := Vector2(0.0, sin(_time * 70.0) * 3.0 * _shake)
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	if _wobble > 0.0:
		var swing := sin(_wobble * 26.0) * deg_to_rad(4.0) * _wobble
		draw_set_transform(Vector2.ZERO, swing, Vector2(1.0 + 0.05 * _wobble, 1.0 - 0.12 * _wobble))

	# Anel de rotacao quando selecionado.
	if is_selected:
		var ring_color := Color(SELECT_COLOR.r, SELECT_COLOR.g, SELECT_COLOR.b, 0.22 + pulse * 0.18)
		for i in range(4):
			var start := _time * 0.8 + i * PI * 0.5
			draw_arc(Vector2.ZERO, half + 14.0, start, start + PI * 0.32, 16, ring_color, 3.0, true)
		draw_rect(Rect2(-half - 8, -13, half * 2.0 + 16, 26), Color(SELECT_COLOR.r, SELECT_COLOR.g, SELECT_COLOR.b, 0.12 + pulse * 0.1))
	elif is_hovered and can_rotate:
		draw_rect(Rect2(-half - 6, -11, half * 2.0 + 12, 22), Color(0.7, 0.9, 1.0, 0.12))

	# Sombra.
	draw_rect(Rect2(Vector2(-half - 2, -6) + Vector2(3, 5), Vector2(half * 2.0 + 4, 14)), Color(0.0, 0.0, 0.0, 0.35))

	if is_splitter():
		_draw_splitter(half, shake_offset)
	else:
		_draw_mirror(half, shake_offset)

	if has_ghost:
		_draw_ghost(half, pulse)

	# Pivo central.
	draw_circle(shake_offset, 6.0, Color(0.08, 0.1, 0.16))
	draw_circle(shake_offset, 6.0, Color(0.6, 0.75, 0.95, 0.9) if can_rotate else Color(0.45, 0.5, 0.58), false, 1.5, true)

	_draw_badge()


func _draw_mirror(half: float, offset: Vector2) -> void:
	var frame_color := Color(0.16, 0.21, 0.32) if can_rotate else Color(0.2, 0.22, 0.26)
	var rim_color := Color(0.55, 0.72, 0.95) if can_rotate else Color(0.42, 0.47, 0.55)
	if is_selected:
		rim_color = SELECT_COLOR

	var frame := Rect2(Vector2(-half - 3, -8) + offset, Vector2(half * 2.0 + 6, 16))
	draw_rect(frame, frame_color)

	# Face espelhada com gradiente.
	var bright := Color(0.92, 0.98, 1.0) if can_rotate else Color(0.7, 0.78, 0.86)
	var dark := Color(0.42, 0.58, 0.8) if can_rotate else Color(0.36, 0.42, 0.5)
	bright = bright.lerp(Color.WHITE, _flash)
	var face := PackedVector2Array([
		Vector2(-half, -5) + offset, Vector2(half, -5) + offset,
		Vector2(half, 4) + offset, Vector2(-half, 4) + offset,
	])
	draw_polygon(face, PackedColorArray([bright, bright, dark, dark]))

	# Brilho que desliza pela superficie.
	var shine_x := fmod(_time * 70.0, half * 2.0 + 60.0) - half - 30.0
	if shine_x > -half + 6.0 and shine_x < half - 10.0:
		var shine := PackedVector2Array([
			Vector2(shine_x, -5) + offset, Vector2(shine_x + 10.0, -5) + offset,
			Vector2(shine_x + 4.0, 4) + offset, Vector2(shine_x - 6.0, 4) + offset,
		])
		draw_colored_polygon(shine, Color(1, 1, 1, 0.55))

	draw_rect(frame, rim_color, false, 2.0 if is_selected else 1.5)

	if not can_rotate:
		for x in [-half + 8.0, half - 8.0]:
			draw_circle(Vector2(x, 0) + offset, 2.5, Color(0.12, 0.13, 0.16))


func _draw_splitter(half: float, offset: Vector2) -> void:
	var rim_color := Color(0.78, 0.66, 1.0) if can_rotate else Color(0.55, 0.5, 0.68)
	if is_selected:
		rim_color = SELECT_COLOR

	var glass := Rect2(Vector2(-half, -5) + offset, Vector2(half * 2.0, 10))
	draw_rect(glass, Color(0.62, 0.5, 1.0, 0.28 + _flash * 0.3))

	# Linhas diagonais simulando vidro semi-espelhado.
	var step := 12.0
	var x := -half + 4.0
	while x < half - 4.0:
		draw_line(Vector2(x, 4) + offset, Vector2(minf(x + 6.0, half), -4) + offset, Color(0.95, 0.9, 1.0, 0.45), 1.5, true)
		x += step

	draw_line(Vector2(-half, 0) + offset, Vector2(half, 0) + offset, Color(1, 1, 1, 0.35), 1.0, true)
	draw_rect(glass, rim_color, false, 2.0 if is_selected else 1.5)

	# Presilhas nas pontas.
	for end_x in [-half - 3.0, half - 5.0]:
		draw_rect(Rect2(Vector2(end_x, -9) + offset, Vector2(8, 18)), Color(0.18, 0.2, 0.3))
		draw_rect(Rect2(Vector2(end_x, -9) + offset, Vector2(8, 18)), rim_color, false, 1.0)


func _draw_ghost(half: float, pulse: float) -> void:
	var relative := deg_to_rad(ghost_degrees) - rotation
	var direction := Vector2(cos(relative), sin(relative))
	var color := Color(0.55, 1.0, 0.7, 0.45 + pulse * 0.45)
	draw_line(-direction * half, direction * half, Color(0.4, 1.0, 0.6, 0.12), 16.0, true)
	draw_dashed_line(-direction * half, direction * half, color, 3.0, 9.0, true, true)
	draw_circle(direction * half, 4.0, color)
	draw_circle(-direction * half, 4.0, color)


func _draw_badge() -> void:
	# Desenha o numero (ou cadeado) sempre de pe, independente da rotacao do espelho.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var center := Vector2(0, -40)

	if can_rotate and number > 0:
		var fill := SELECT_COLOR if is_selected else Color(0.09, 0.14, 0.24, 0.95)
		var text_color := Color(0.08, 0.06, 0.02) if is_selected else Color(0.9, 0.95, 1.0)
		draw_circle(center, 12.0, fill)
		draw_circle(center, 12.0, Color(0.55, 0.75, 1.0, 0.8) if not is_selected else Color(1, 0.95, 0.7), false, 1.5, true)
		draw_string(UI.font(800), center + Vector2(-12, 6), str(number), HORIZONTAL_ALIGNMENT_CENTER, 24.0, 16, text_color)
	elif not can_rotate:
		draw_circle(center, 12.0, Color(0.12, 0.13, 0.17, 0.95))
		draw_circle(center, 12.0, Color(0.5, 0.55, 0.62, 0.9), false, 1.5, true)
		draw_arc(center + Vector2(0, -2), 4.0, PI, TAU, 10, Color(0.8, 0.84, 0.9), 2.0, true)
		draw_rect(Rect2(center + Vector2(-5.5, -2), Vector2(11, 8)), Color(0.8, 0.84, 0.9))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
