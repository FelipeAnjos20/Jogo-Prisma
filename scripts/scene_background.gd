extends Node2D

var time = 0.0

const ROOM_RECT = Rect2(48.0, 86.0, 1184.0, 572.0)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.018, 0.026, 0.052), true)
	_draw_grid()
	_draw_floor_panels()
	_draw_prism_marks()
	_draw_corner_lights()


func _draw_grid() -> void:
	var grid_color = Color(0.22, 0.45, 0.62, 0.12)
	var bright_line = Color(0.32, 0.66, 0.86, 0.22)

	for x in range(80, 1220, 40):
		var color = bright_line if x % 160 == 0 else grid_color
		draw_line(Vector2(x, ROOM_RECT.position.y), Vector2(x, ROOM_RECT.end.y), color, 1.0)

	for y in range(120, 640, 40):
		var color = bright_line if y % 160 == 0 else grid_color
		draw_line(Vector2(ROOM_RECT.position.x, y), Vector2(ROOM_RECT.end.x, y), color, 1.0)


func _draw_floor_panels() -> void:
	var panel_color = Color(0.06, 0.09, 0.14, 0.65)
	var edge_color = Color(0.18, 0.33, 0.44, 0.32)

	for x in range(88, 1180, 220):
		for y in range(130, 610, 160):
			var rect = Rect2(Vector2(x, y), Vector2(170, 105))
			draw_rect(rect, panel_color, true)
			draw_rect(rect, edge_color, false, 1.0)


func _draw_prism_marks() -> void:
	for index in range(5):
		var x = 180.0 + index * 220.0
		var y = 112.0 + sin(time * 0.8 + index) * 4.0
		var alpha = 0.14 + 0.08 * (0.5 + 0.5 * sin(time + index))
		var points = PackedVector2Array([
			Vector2(x, y),
			Vector2(x + 28.0, y + 46.0),
			Vector2(x - 28.0, y + 46.0),
			Vector2(x, y),
		])
		draw_polyline(points, Color(0.65, 0.78, 1.0, alpha), 2.0)


func _draw_corner_lights() -> void:
	var pulse = 0.5 + 0.5 * sin(time * 1.4)
	var glow = Color(0.2, 0.85, 1.0, 0.12 + pulse * 0.08)
	var core = Color(0.75, 1.0, 1.0, 0.55)
	var points = [
		Vector2(64, 102),
		Vector2(1216, 102),
		Vector2(64, 642),
		Vector2(1216, 642),
	]

	for point in points:
		draw_circle(point, 22.0 + pulse * 4.0, glow)
		draw_circle(point, 4.0, core)
