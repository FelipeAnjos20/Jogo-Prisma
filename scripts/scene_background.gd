extends Node2D

# Cenario desenhado por codigo: fundo em gradiente, sala do laboratorio de luz,
# grade, particulas de poeira luminosa e vinheta.

@export var show_room := true

const SCREEN := Vector2(1280.0, 720.0)
const ROOM_RECT := Rect2(40.0, 100.0, 1200.0, 590.0)
const MOTE_COUNT := 46
const TemasScript := preload("res://scripts/temas.gd")
const UI := preload("res://scripts/ui_kit.gd")
const BeamScript := preload("res://scripts/light_beam.gd")

var time := 0.0
var _motes: Array = []
var _is_level := false
var _theme_index := -1
var _theme: Dictionary = {}
var _beam: Node2D
var _light_timer := 0.0


func _ready() -> void:
	_is_level = get_parent().scene_file_path == "res://scenes/main.tscn"
	if _is_level:
		_beam = get_parent().get_node_or_null("Puzzle/LightBeam")
		_sync_theme()
	for i in range(MOTE_COUNT):
		_motes.append({
			"position": Vector2(randf_range(0.0, SCREEN.x), randf_range(0.0, SCREEN.y)),
			"speed": randf_range(6.0, 22.0),
			"size": randf_range(1.0, 2.6),
			"phase": randf() * TAU,
			"light": Color(0, 0, 0, 0),
			"target_light": Color(0, 0, 0, 0),
		})


func _process(delta: float) -> void:
	time += delta
	_sync_theme()
	_light_timer -= delta
	var sample_light := _light_timer <= 0.0
	if sample_light:
		_light_timer = 0.05
	var reduced := _reduced_effects()
	for mote in _motes:
		var position_m: Vector2 = mote["position"]
		if not reduced:
			position_m.y -= float(mote["speed"]) * delta
			position_m.x += sin(time * 0.6 + float(mote["phase"])) * 8.0 * delta
		if position_m.y < -10.0:
			position_m = Vector2(randf_range(0.0, SCREEN.x), SCREEN.y + 10.0)
		mote["position"] = position_m
		if sample_light and is_instance_valid(_beam):
			mote["target_light"] = luz_no_ponto(to_global(position_m), _beam.get("segments"), _beam.call("get_visible_distance"))
		var light: Color = mote["light"]
		mote["light"] = light.lerp(mote["target_light"], 1.0 - exp(-delta * 10.0))
	queue_redraw()


func _sync_theme() -> void:
	if not _is_level:
		return
	var state := get_tree().root.get_node_or_null("GameState")
	if state != null and _theme_index != int(state.get("current_level")):
		_theme_index = int(state.get("current_level"))
		_theme = TemasScript.cor_da_fase(_theme_index)
		for mote in _motes:
			mote["light"] = Color(0, 0, 0, 0)
			mote["target_light"] = Color(0, 0, 0, 0)


func _reduced_effects() -> bool:
	var state := get_tree().root.get_node_or_null("GameState")
	return state != null and state.get("reduce_effects") == true


# No maximo 46 particulas x 64 trechos, amostrados a 20 Hz.
static func luz_no_ponto(point: Vector2, beam_segments: Array, distance_limit := INF) -> Color:
	var result := Color(0, 0, 0, 0)
	for segment in beam_segments:
		var start: Vector2 = segment["a"]
		var length := BeamScript.visible_length(segment, distance_limit)
		if length <= 0.01:
			continue
		var end: Vector2 = start.move_toward(segment["b"], length)
		var closest := Geometry2D.get_closest_point_to_segment(point, start, end)
		var strength := maxf(0.0, 1.0 - point.distance_to(closest) / 48.0)
		if strength * strength > result.a:
			result = UI.light_color(segment["color"])
			result.a = strength * strength
	return result


func _draw() -> void:
	_draw_gradient()
	if show_room:
		_draw_room()
	else:
		_draw_free_grid()
	_draw_motes()
	_draw_vignette()


func _draw_gradient() -> void:
	var top := Color(0.02, 0.03, 0.07)
	var bottom := Color(0.035, 0.02, 0.07)
	if not _theme.is_empty():
		top = _theme["fundo"]
		bottom = _theme["sala"]
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(SCREEN.x, 0), SCREEN, Vector2(0, SCREEN.y)]),
		PackedColorArray([top, top, bottom, bottom])
	)
	# Manchas de luz coloridas ao fundo.
	if _theme.is_empty():
		draw_circle(Vector2(260, 620), 320.0, Color(0.25, 0.1, 0.45, 0.06))
		draw_circle(Vector2(1060, 180), 360.0, Color(0.05, 0.3, 0.45, 0.06))
	else:
		var accent: Color = _theme["acento"]
		draw_circle(Vector2(260, 620), 320.0, Color(accent.r, accent.g, accent.b, 0.035))
		draw_circle(Vector2(1060, 180), 360.0, Color(accent.r, accent.g, accent.b, 0.04))


func _draw_room() -> void:
	var room := ROOM_RECT
	draw_rect(room, _theme.get("sala", Color(0.025, 0.04, 0.075, 0.9)))

	var grid_color := Color(0.25, 0.5, 0.75, 0.07)
	var major_color := Color(0.3, 0.62, 0.9, 0.14)
	var accent: Color = _theme.get("acento", Color(0.5, 0.78, 1.0))
	if not _theme.is_empty():
		grid_color = _theme["grade"]
		major_color = Color(accent.r, accent.g, accent.b, 0.16)
	var x := room.position.x + 40.0
	while x < room.end.x:
		var major := int(x - room.position.x) % 160 == 0
		draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), major_color if major else grid_color, 1.0)
		x += 40.0
	var y := room.position.y + 40.0
	while y < room.end.y:
		var major := int(y - room.position.y) % 160 == 0
		draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), major_color if major else grid_color, 1.0)
		y += 40.0

	# Pontos nos cruzamentos principais.
	x = room.position.x + 160.0
	while x < room.end.x:
		y = room.position.y + 160.0
		while y < room.end.y:
			draw_circle(Vector2(x, y), 2.0, Color(accent.r, accent.g, accent.b, 0.25))
			y += 160.0
		x += 160.0

	# Paredes com borda luminosa.
	var pulse := 0.5 + 0.5 * sin(time * 1.3)
	if _reduced_effects():
		pulse = 0.35
	draw_rect(room.grow(10.0), accent.darkened(0.8), false, 12.0)
	draw_rect(room.grow(4.0), Color(accent.r, accent.g, accent.b, 0.1 + pulse * 0.06), false, 4.0)
	draw_rect(room, Color(accent.r, accent.g, accent.b, 0.55), false, 1.5)

	# Cantoneiras.
	var corner_color := accent.lightened(0.3)
	corner_color.a = 0.8
	var corners := [
		[room.position, Vector2(1, 1)],
		[Vector2(room.end.x, room.position.y), Vector2(-1, 1)],
		[room.end, Vector2(-1, -1)],
		[Vector2(room.position.x, room.end.y), Vector2(1, -1)],
	]
	for entry in corners:
		var point: Vector2 = entry[0]
		var sign_v: Vector2 = entry[1]
		draw_line(point, point + Vector2(28 * sign_v.x, 0), corner_color, 3.0)
		draw_line(point, point + Vector2(0, 28 * sign_v.y), corner_color, 3.0)
		draw_circle(point + sign_v * 10.0, 3.0 + pulse, Color(accent.r, accent.g, accent.b, 0.6))

	# Linha de varredura suave.
	var scan_y := room.position.y + fmod(time * 40.0, room.size.y)
	if not _reduced_effects():
		draw_line(Vector2(room.position.x, scan_y), Vector2(room.end.x, scan_y), Color(accent.r, accent.g, accent.b, 0.04), 18.0)


func _draw_free_grid() -> void:
	var grid_color := Color(0.25, 0.5, 0.75, 0.05)
	var offset := 0.0 if _reduced_effects() else fmod(time * 10.0, 40.0)
	var x := -40.0 + offset
	while x < SCREEN.x:
		draw_line(Vector2(x, 0), Vector2(x, SCREEN.y), grid_color, 1.0)
		x += 40.0
	var y := -40.0 + offset
	while y < SCREEN.y:
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y), grid_color, 1.0)
		y += 40.0


func _draw_motes() -> void:
	var reduced := _reduced_effects()
	for mote in _motes:
		var twinkle := 0.5 if reduced else 0.5 + 0.5 * sin(time * 2.0 + float(mote["phase"]))
		var size: float = mote["size"]
		draw_circle(mote["position"], size * 2.5, Color(0.6, 0.85, 1.0, 0.04 * twinkle))
		draw_circle(mote["position"], size, Color(0.75, 0.9, 1.0, 0.18 + 0.3 * twinkle))
		var light: Color = mote["light"]
		if light.a > 0.01:
			draw_circle(mote["position"], size * 4.0, Color(light.r, light.g, light.b, light.a * 0.14))
			draw_circle(mote["position"], size * 1.3, Color(light.r, light.g, light.b, light.a * 0.8))


func _draw_vignette() -> void:
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	var dark := Color(0.0, 0.0, 0.02, 0.55)
	if not _theme.is_empty():
		dark = _theme["vinheta"]
	var band := 150.0
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(SCREEN.x, 0), Vector2(SCREEN.x, band), Vector2(0, band)]), PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, SCREEN.y - band), Vector2(SCREEN.x, SCREEN.y - band), SCREEN, Vector2(0, SCREEN.y)]), PackedColorArray([clear, clear, dark, dark]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(band, 0), Vector2(band, SCREEN.y), Vector2(0, SCREEN.y)]), PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(SCREEN.x - band, 0), Vector2(SCREEN.x, 0), SCREEN, Vector2(SCREEN.x - band, SCREEN.y)]), PackedColorArray([clear, dark, dark, clear]))
