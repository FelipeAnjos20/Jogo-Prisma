extends Node2D

# Desenha o feixe de luz. O calculo do caminho (reflexao, divisor, filtro, prisma, bloqueios,
# paredes e cristais) fica em scripts/feixe.gd, que e puro e coberto por tests/run_tests.gd.
# Aqui os nodes da cena sao convertidos em dados e o resultado e desenhado com brilho e particulas.

const UI := preload("res://scripts/ui_kit.gd")
const Feixe := preload("res://scripts/feixe.gd")

const PULSE_SPEED := 360.0
const PULSE_SPACING := 90.0
const MAX_SPARKS := 160
const INTRO_DELAY := 0.18
const INTRO_DURATION := 0.6

var segments: Array = []
var hits: Array = []
var energized_prisms: Array = []
# Reflexoes em espelhos/divisores: {position, incoming, outgoing, normal, angle, mirror (node), color}
var reflections: Array = []

var _pulse_offset := 0.0
var _sparks: Array = []
var _spark_timer := 0.0
var _intro_age := INTRO_DELAY + INTRO_DURATION
var _visible_distance := INF


func play_intro() -> void:
	_intro_age = 0.0
	_visible_distance = 0.0
	_sparks.clear()
	_spark_timer = 0.0
	queue_redraw()


func get_visible_distance() -> float:
	return _visible_distance


# Recorta apenas a apresentacao; os dados do calculo ficam intactos.
static func visible_length(segment: Dictionary, distance_limit: float) -> float:
	var start: Vector2 = segment["a"]
	var end: Vector2 = segment["b"]
	return clampf(distance_limit - float(segment["distance"]), 0.0, start.distance_to(end))


func _reduced_effects() -> bool:
	var state := get_tree().root.get_node_or_null("GameState")
	return state != null and state.get("reduce_effects") == true


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func _process(delta: float) -> void:
	var reduced := _reduced_effects()
	_intro_age += delta
	_visible_distance = INF
	if not reduced and _intro_age < INTRO_DELAY + INTRO_DURATION:
		var path_length := 0.0
		for segment in segments:
			var start: Vector2 = segment["a"]
			path_length = maxf(path_length, float(segment["distance"]) + start.distance_to(segment["b"]))
		_visible_distance = path_length * clampf((_intro_age - INTRO_DELAY) / INTRO_DURATION, 0.0, 1.0)
	_pulse_offset = fmod(_pulse_offset + PULSE_SPEED * delta, PULSE_SPACING)
	if reduced:
		_sparks.clear()
	else:
		_update_sparks(delta)
	queue_redraw()


# Retorna um Array[bool] dizendo quais cristais estao recebendo a luz correta.
func trace(emitter: Node2D, mirrors: Array, filters: Array, obstacles: Array, crystals: Array, prisms: Array, room: Rect2) -> Array:
	var surfaces: Array = []
	var owner_id := 0

	for mirror in mirrors:
		var segment: PackedVector2Array = mirror.get_light_segment()
		surfaces.append({"a": segment[0], "b": segment[1], "tipo": mirror.kind, "dono": owner_id})
		owner_id += 1

	for color_filter in filters:
		var segment: PackedVector2Array = color_filter.get_light_segment()
		surfaces.append({"a": segment[0], "b": segment[1], "tipo": "filter", "cor": color_filter.color_name, "dono": owner_id})
		owner_id += 1

	for obstacle in obstacles:
		for edge in obstacle.get_light_edges():
			surfaces.append({"a": edge[0], "b": edge[1], "tipo": "obstacle", "dono": owner_id})
		owner_id += 1

	var crystal_data: Array = []
	for crystal in crystals:
		crystal_data.append({"centro": crystal.global_position, "raio": crystal.get_light_radius(), "cor": crystal.required_color})

	var prism_data: Array = []
	for prism in prisms:
		prism_data.append({"centro": prism.global_position, "raio": prism.get_light_radius()})

	var result := Feixe.tracar(emitter.global_position, Vector2.RIGHT.rotated(emitter.global_rotation), surfaces, crystal_data, prism_data, room)
	segments = result["segments"]
	hits = result["hits"]
	energized_prisms.clear()
	for index in result["energized"]:
		energized_prisms.append(prisms[index])

	# Os espelhos usam os donos 0..n-1, entao o dono aponta direto para o node.
	reflections.clear()
	for reflection in result["reflections"]:
		var owner_index: int = reflection["owner"]
		if owner_index >= 0 and owner_index < mirrors.size():
			var entry: Dictionary = reflection.duplicate()
			entry["mirror"] = mirrors[owner_index]
			reflections.append(entry)
	return result["lit"]


# ---------------------------------------------------------------- efeitos

# Vitoria: faiscas saem de todo o caminho da luz, na cor de cada trecho.
func celebrate() -> void:
	for segment in segments:
		var start := to_local(segment["a"])
		var end := to_local(segment["b"])
		var length := start.distance_to(end)
		if length < 1.0:
			continue
		var color := UI.light_color(segment["color"])
		var normal := (end - start).normalized().orthogonal()
		for i in range(int(clampf(length / 22.0, 2.0, 40.0))):
			var side := 1.0 if randf() < 0.5 else -1.0
			_sparks.append({
				"position": start.lerp(end, randf()),
				"velocity": normal * side * randf_range(120.0, 320.0),
				"age": 0.0,
				"life": randf_range(0.6, 1.2),
				"color": color,
			})


func _update_sparks(delta: float) -> void:
	_spark_timer += delta
	if _spark_timer >= 0.03:
		_spark_timer = 0.0
		for hit in hits:
			if not _hit_visible(hit):
				continue
			if _sparks.size() >= MAX_SPARKS:
				break
			var angle := randf() * TAU
			_sparks.append({
				"position": to_local(hit["position"]),
				"velocity": Vector2(cos(angle), sin(angle)) * randf_range(40.0, 130.0),
				"age": 0.0,
				"life": randf_range(0.2, 0.45),
				"color": UI.light_color(hit["color"]),
			})

	for spark in _sparks:
		spark["age"] += delta
		spark["position"] += spark["velocity"] * delta
		spark["velocity"] *= 0.9
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return s["age"] < s["life"])


func _draw() -> void:
	for segment in segments:
		var start := to_local(segment["a"])
		var full_end := to_local(segment["b"])
		var length := visible_length(segment, _visible_distance)
		if length <= 0.01:
			continue
		var end := start.move_toward(full_end, length)
		var color := UI.light_color(segment["color"])
		_draw_glow_line(start, end, color)
		if length < start.distance_to(full_end):
			draw_circle(end, 15.0, Color(color.r, color.g, color.b, 0.22))
			draw_circle(end, 4.0, Color(1, 1, 1, 0.9))

	if not _reduced_effects():
		for segment in segments:
			_draw_segment_pulses(segment)

	for hit in hits:
		if not _hit_visible(hit):
			continue
		var point := to_local(hit["position"])
		var color := UI.light_color(hit["color"])
		var radius := 9.0 if hit["strong"] else 6.0
		draw_circle(point, radius * 2.2, Color(color.r, color.g, color.b, 0.12))
		draw_circle(point, radius, Color(color.r, color.g, color.b, 0.45))
		draw_circle(point, radius * 0.45, Color(1, 1, 1, 0.9))

	for spark in _sparks:
		var fade := 1.0 - float(spark["age"]) / float(spark["life"])
		var spark_color: Color = spark["color"]
		var tail: Vector2 = spark["velocity"] * 0.06
		draw_line(spark["position"], spark["position"] - tail, Color(spark_color.r, spark_color.g, spark_color.b, fade), 2.0, true)


func _hit_visible(hit: Dictionary) -> bool:
	if _visible_distance == INF:
		return true
	for segment in segments:
		var end: Vector2 = segment["b"]
		if end.distance_squared_to(hit["position"]) < 0.25:
			var start: Vector2 = segment["a"]
			if float(segment["distance"]) + start.distance_to(end) <= _visible_distance:
				return true
	return false


func _draw_glow_line(start: Vector2, end: Vector2, color: Color) -> void:
	# Camadas somadas (blend aditivo) criam o brilho.
	draw_line(start, end, Color(color.r, color.g, color.b, 0.07), 30.0, true)
	draw_line(start, end, Color(color.r, color.g, color.b, 0.14), 16.0, true)
	draw_line(start, end, Color(color.r, color.g, color.b, 0.55), 7.0, true)
	draw_line(start, end, Color(1.0, 1.0, 1.0, 0.75), 2.5, true)
	draw_circle(start, 8.0, Color(color.r, color.g, color.b, 0.12))


func _draw_segment_pulses(segment: Dictionary) -> void:
	var start: Vector2 = segment["a"]
	var end: Vector2 = segment["b"]
	var length := visible_length(segment, _visible_distance)
	var full_length := start.distance_to(end)
	if length < 1.0:
		return

	var color := UI.light_color(segment["color"])
	var begin: float = segment["distance"]
	var first_index := ceilf((begin - _pulse_offset) / PULSE_SPACING)
	var along := _pulse_offset + first_index * PULSE_SPACING - begin

	var color_name: String = segment["color"]
	while along <= length:
		var point := to_local(start.lerp(end, along / full_length))
		draw_circle(point, 9.0, Color(color.r, color.g, color.b, 0.22))
		if color_name == "white":
			draw_circle(point, 4.0, Color(1, 1, 1, 0.8))
		else:
			# Pulsos com forma da cor (acessibilidade para daltonicos).
			UI.draw_color_symbol(self, point, 5.5, color_name, Color(1, 1, 1, 0.75))
		along += PULSE_SPACING
