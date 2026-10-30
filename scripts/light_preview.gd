extends Node2D

# Previa da luz: com o mouse sobre um espelho, mostra fraquinho (tracejado) para onde o
# raio iria no proximo giro (+15 graus, o mesmo do clique ou da tecla E).
# Usa o calculo puro de scripts/feixe.gd, sem mexer no feixe de verdade.

const UI := preload("res://scripts/ui_kit.gd")
const Feixe := preload("res://scripts/feixe.gd")
const Geometria = preload("res://scripts/geometria.gd")

const STEP_DEGREES := 15.0
const DASH := 10.0
const FADE_SPEED := 4.0
# Distancia minima para um trecho contar como "diferente" do raio atual.
const SAME_TOLERANCE := 1.5

var _segments: Array = []
var _target: Node2D = null
var _alpha := 0.0
var _time := 0.0


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


# Recalcula a previa para o espelho alvo (null esconde). current_segments e o raio atual.
func update_preview(target: Node2D, mirrors: Array, filters: Array, obstacles: Array, crystals: Array, prisms: Array, emitter: Node2D, room: Rect2, current_segments: Array) -> void:
	if target == null or not target.can_rotate or not target.is_settled():
		_target = null
		return
	_target = target
	var next_degrees := Geometria.proximo_angulo(target.target_degrees, 1, STEP_DEGREES)
	var result := Feixe.tracar(emitter.global_position, Vector2.RIGHT.rotated(emitter.global_rotation),
		_surfaces(target, next_degrees, mirrors, filters, obstacles), _crystal_data(crystals), _prism_data(prisms), room)
	_segments.clear()
	for segment in result["segments"]:
		if not _exists_in(segment, current_segments):
			_segments.append(segment)


func _process(delta: float) -> void:
	_time += delta
	_alpha = move_toward(_alpha, 1.0 if _target != null else 0.0, delta * FADE_SPEED)
	queue_redraw()


func _surfaces(target: Node2D, next_degrees: float, mirrors: Array, filters: Array, obstacles: Array) -> Array:
	var surfaces: Array = []
	var owner_id := 0
	for mirror in mirrors:
		var a: Vector2
		var b: Vector2
		if mirror == target:
			var seg := Feixe.segmento(mirror.global_position, next_degrees, mirror.half_length())
			a = seg[0]
			b = seg[1]
		else:
			var segment: PackedVector2Array = mirror.get_light_segment()
			a = segment[0]
			b = segment[1]
		surfaces.append({"a": a, "b": b, "tipo": mirror.kind, "dono": owner_id})
		owner_id += 1
	for color_filter in filters:
		var segment: PackedVector2Array = color_filter.get_light_segment()
		surfaces.append({"a": segment[0], "b": segment[1], "tipo": "filter", "cor": color_filter.color_name, "dono": owner_id})
		owner_id += 1
	for obstacle in obstacles:
		for edge in obstacle.get_light_edges():
			surfaces.append({"a": edge[0], "b": edge[1], "tipo": "obstacle", "dono": owner_id})
		owner_id += 1
	return surfaces


func _crystal_data(crystals: Array) -> Array:
	var data: Array = []
	for crystal in crystals:
		data.append({"centro": crystal.global_position, "raio": crystal.get_light_radius(), "cor": crystal.required_color})
	return data


func _prism_data(prisms: Array) -> Array:
	var data: Array = []
	for prism in prisms:
		data.append({"centro": prism.global_position, "raio": prism.get_light_radius()})
	return data


# O trecho ja existe no raio atual? (So o caminho novo e desenhado.)
func _exists_in(segment: Dictionary, current_segments: Array) -> bool:
	for other in current_segments:
		if segment["color"] == other["color"] \
			and (segment["a"] as Vector2).distance_to(other["a"]) < SAME_TOLERANCE \
			and (segment["b"] as Vector2).distance_to(other["b"]) < SAME_TOLERANCE:
			return true
	return false


func _draw() -> void:
	if _alpha <= 0.01:
		return
	# Tracejado que "anda" no sentido da luz.
	var offset := fmod(_time * 40.0, DASH * 2.0)
	for segment in _segments:
		var start := to_local(segment["a"])
		var end := to_local(segment["b"])
		var length := start.distance_to(end)
		if length < 1.0:
			continue
		var color := UI.light_color(segment["color"])
		var direction := (end - start) / length
		draw_line(start, end, Color(color.r, color.g, color.b, 0.05 * _alpha), 10.0, true)
		var along := -offset
		while along < length:
			var from := maxf(along, 0.0)
			var to := minf(along + DASH, length)
			if to > from:
				draw_line(start + direction * from, start + direction * to, Color(color.r, color.g, color.b, 0.45 * _alpha), 2.0, true)
			along += DASH * 2.0
		draw_circle(end, 3.0, Color(color.r, color.g, color.b, 0.5 * _alpha))
