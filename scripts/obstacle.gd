extends StaticBody2D

var obstacle_size = Vector2(80.0, 180.0)
var is_active := true


func configure(level_position: Vector2, level_size: Vector2, level_active: bool) -> void:
	position = level_position
	obstacle_size = level_size
	visible = level_active
	is_active = level_active

	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node != null:
		shape_node.disabled = not level_active

		if shape_node.shape is RectangleShape2D:
			shape_node.shape.size = obstacle_size

	queue_redraw()


func get_light_edges() -> Array:
	var half_size = obstacle_size * 0.5
	var corners = [
		to_global(Vector2(-half_size.x, -half_size.y)),
		to_global(Vector2(half_size.x, -half_size.y)),
		to_global(Vector2(half_size.x, half_size.y)),
		to_global(Vector2(-half_size.x, half_size.y)),
	]

	return [
		[corners[0], corners[1]],
		[corners[1], corners[2]],
		[corners[2], corners[3]],
		[corners[3], corners[0]],
	]


func _draw() -> void:
	var rect = Rect2(-obstacle_size * 0.5, obstacle_size)
	draw_rect(rect, Color(0.85, 0.16, 0.22, 1.0), true)
	draw_rect(rect, Color(1.0, 0.72, 0.35, 1.0), false, 3.0)
