extends Node2D

# Filtro de cor: a luz branca atravessa e sai colorida. Luz de outra cor e bloqueada.

const UI := preload("res://scripts/ui_kit.gd")
const LENGTH := 100.0

var color_name := "red"
var _time := 0.0


func configure(data: Dictionary) -> void:
	position = data["position"]
	rotation_degrees = data["rotation"]
	color_name = data["color"]
	_time = randf() * 10.0


func get_light_segment() -> PackedVector2Array:
	var half := LENGTH * 0.5
	return PackedVector2Array([to_global(Vector2(-half, 0.0)), to_global(Vector2(half, 0.0))])


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var half := LENGTH * 0.5
	var color := UI.light_color(color_name)
	var pulse := 0.5 + 0.5 * sin(_time * 2.5)

	draw_rect(Rect2(-half - 6, -14, LENGTH + 12, 28), Color(color.r, color.g, color.b, 0.08 + pulse * 0.06))
	draw_rect(Rect2(-half, -7, LENGTH, 14), Color(color.r, color.g, color.b, 0.32))
	draw_rect(Rect2(-half, -2, LENGTH, 4), Color(color.r, color.g, color.b, 0.55))

	# Ondas de energia correndo pelo filtro.
	for i in range(3):
		var x := fmod(_time * 40.0 + i * LENGTH / 3.0, LENGTH) - half
		draw_line(Vector2(x, -7), Vector2(x, 7), Color(1, 1, 1, 0.25), 2.0)

	draw_rect(Rect2(-half, -7, LENGTH, 14), color.lightened(0.3), false, 1.5)

	for end_x in [-half - 8.0, half]:
		draw_rect(Rect2(end_x, -11, 8, 22), Color(0.16, 0.19, 0.28))
		draw_rect(Rect2(end_x, -11, 8, 22), color, false, 1.0)

	# Simbolo da cor, sempre de pe, alem da ponta do filtro (acessibilidade).
	draw_set_transform(Vector2(-half - 22.0, 0.0), -rotation, Vector2.ONE)
	draw_circle(Vector2.ZERO, 11.0, Color(0.04, 0.06, 0.12, 0.95))
	draw_circle(Vector2.ZERO, 11.0, color, false, 1.5, true)
	UI.draw_color_symbol(self, Vector2.ZERO, 6.5, color_name, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
