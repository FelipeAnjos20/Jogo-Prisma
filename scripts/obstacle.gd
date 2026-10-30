extends Node2D

# Bloco absorvedor: qualquer feixe que toca nele e interrompido.

var obstacle_size := Vector2(80.0, 180.0)
var _time := 0.0


func configure(data: Dictionary) -> void:
	position = data["position"]
	obstacle_size = data["size"]
	_time = randf() * 10.0
	queue_redraw()


func get_light_edges() -> Array:
	var half := obstacle_size * 0.5
	var corners := [
		to_global(Vector2(-half.x, -half.y)),
		to_global(Vector2(half.x, -half.y)),
		to_global(Vector2(half.x, half.y)),
		to_global(Vector2(-half.x, half.y)),
	]
	return [
		[corners[0], corners[1]],
		[corners[1], corners[2]],
		[corners[2], corners[3]],
		[corners[3], corners[0]],
	]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var half := obstacle_size * 0.5
	var rect := Rect2(-half, obstacle_size)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)

	draw_rect(Rect2(rect.position + Vector2(5, 7), rect.size), Color(0.0, 0.0, 0.0, 0.4))
	draw_rect(rect.grow(6.0), Color(1.0, 0.2, 0.28, 0.05 + pulse * 0.05))
	draw_rect(rect, Color(0.1, 0.04, 0.07))

	var inner := rect.grow(-7.0)
	draw_rect(inner, Color(0.17, 0.06, 0.1))

	# Linhas de energia internas.
	var y := inner.position.y + 10.0
	while y < inner.end.y - 4.0:
		var alpha := 0.12 + 0.1 * sin(_time * 3.0 + y * 0.08)
		draw_line(Vector2(inner.position.x + 4, y), Vector2(inner.end.x - 4, y), Color(1.0, 0.3, 0.35, alpha), 2.0)
		y += 14.0

	# Nucleo.
	draw_circle(Vector2.ZERO, minf(half.x, half.y) * 0.35, Color(1.0, 0.25, 0.3, 0.18 + pulse * 0.12))
	draw_circle(Vector2.ZERO, minf(half.x, half.y) * 0.16, Color(1.0, 0.5, 0.5, 0.5 + pulse * 0.3))

	draw_rect(rect, Color(1.0, 0.36, 0.4, 0.75 + pulse * 0.25), false, 2.5)
	draw_rect(inner, Color(1.0, 0.45, 0.4, 0.25), false, 1.0)

	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var inward: Vector2 = (Vector2.ZERO - corner).normalized() * 6.0
		draw_circle(corner + inward, 2.5, Color(1.0, 0.7, 0.55, 0.9))
