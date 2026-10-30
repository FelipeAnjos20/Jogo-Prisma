extends Node2D

# Cenario desenhado por codigo: fundo em gradiente, sala do laboratorio de luz,
# grade, particulas de poeira luminosa e vinheta.

@export var show_room := true

const SCREEN := Vector2(1280.0, 720.0)
const ROOM_RECT := Rect2(40.0, 100.0, 1200.0, 590.0)
const MOTE_COUNT := 46

var time := 0.0
var _motes: Array = []


func _ready() -> void:
	for i in range(MOTE_COUNT):
		_motes.append({
			"position": Vector2(randf_range(0.0, SCREEN.x), randf_range(0.0, SCREEN.y)),
			"speed": randf_range(6.0, 22.0),
			"size": randf_range(1.0, 2.6),
			"phase": randf() * TAU,
		})


func _process(delta: float) -> void:
	time += delta
	for mote in _motes:
		var position_m: Vector2 = mote["position"]
		position_m.y -= float(mote["speed"]) * delta
		position_m.x += sin(time * 0.6 + float(mote["phase"])) * 8.0 * delta
		if position_m.y < -10.0:
			position_m = Vector2(randf_range(0.0, SCREEN.x), SCREEN.y + 10.0)
		mote["position"] = position_m
	queue_redraw()


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
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(SCREEN.x, 0), SCREEN, Vector2(0, SCREEN.y)]),
		PackedColorArray([top, top, bottom, bottom])
	)
	# Manchas de luz coloridas ao fundo.
	draw_circle(Vector2(260, 620), 320.0, Color(0.25, 0.1, 0.45, 0.06))
	draw_circle(Vector2(1060, 180), 360.0, Color(0.05, 0.3, 0.45, 0.06))


func _draw_room() -> void:
	var room := ROOM_RECT
	draw_rect(room, Color(0.025, 0.04, 0.075, 0.9))

	var grid_color := Color(0.25, 0.5, 0.75, 0.07)
	var major_color := Color(0.3, 0.62, 0.9, 0.14)
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
			draw_circle(Vector2(x, y), 2.0, Color(0.5, 0.8, 1.0, 0.25))
			y += 160.0
		x += 160.0

	# Paredes com borda luminosa.
	var pulse := 0.5 + 0.5 * sin(time * 1.3)
	draw_rect(room.grow(10.0), Color(0.08, 0.11, 0.18), false, 12.0)
	draw_rect(room.grow(4.0), Color(0.35, 0.65, 1.0, 0.1 + pulse * 0.06), false, 4.0)
	draw_rect(room, Color(0.5, 0.78, 1.0, 0.55), false, 1.5)

	# Cantoneiras.
	var corner_color := Color(0.7, 0.9, 1.0, 0.8)
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
		draw_circle(point + sign_v * 10.0, 3.0 + pulse, Color(0.4, 0.9, 1.0, 0.6))

	# Linha de varredura suave.
	var scan_y := room.position.y + fmod(time * 40.0, room.size.y)
	draw_line(Vector2(room.position.x, scan_y), Vector2(room.end.x, scan_y), Color(0.4, 0.8, 1.0, 0.04), 18.0)


func _draw_free_grid() -> void:
	var grid_color := Color(0.25, 0.5, 0.75, 0.05)
	var offset := fmod(time * 10.0, 40.0)
	var x := -40.0 + offset
	while x < SCREEN.x:
		draw_line(Vector2(x, 0), Vector2(x, SCREEN.y), grid_color, 1.0)
		x += 40.0
	var y := -40.0 + offset
	while y < SCREEN.y:
		draw_line(Vector2(0, y), Vector2(SCREEN.x, y), grid_color, 1.0)
		y += 40.0


func _draw_motes() -> void:
	for mote in _motes:
		var twinkle := 0.5 + 0.5 * sin(time * 2.0 + float(mote["phase"]))
		var size: float = mote["size"]
		draw_circle(mote["position"], size * 2.5, Color(0.6, 0.85, 1.0, 0.04 * twinkle))
		draw_circle(mote["position"], size, Color(0.75, 0.9, 1.0, 0.18 + 0.3 * twinkle))


func _draw_vignette() -> void:
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	var dark := Color(0.0, 0.0, 0.02, 0.55)
	var band := 150.0
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(SCREEN.x, 0), Vector2(SCREEN.x, band), Vector2(0, band)]), PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, SCREEN.y - band), Vector2(SCREEN.x, SCREEN.y - band), SCREEN, Vector2(0, SCREEN.y)]), PackedColorArray([clear, clear, dark, dark]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(band, 0), Vector2(band, SCREEN.y), Vector2(0, SCREEN.y)]), PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(SCREEN.x - band, 0), Vector2(SCREEN.x, 0), SCREEN, Vector2(SCREEN.x - band, SCREEN.y)]), PackedColorArray([clear, dark, dark, clear]))
