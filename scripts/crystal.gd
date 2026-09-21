extends Area2D

signal activated

var is_active := false
var pulse_time := 0.0

const RADIUS = 28.0
const INACTIVE_COLOR = Color(0.1, 0.55, 0.85)
const ACTIVE_COLOR = Color(0.25, 1.0, 0.55)
const CORE_COLOR = Color(0.9, 1.0, 1.0)


func activate_from_light() -> void:
	# Called by the light beam when a ray segment reaches this Area2D.
	if is_active:
		return

	is_active = true
	pulse_time = 0.0
	activated.emit()
	queue_redraw()


func reset_crystal() -> void:
	is_active = false
	pulse_time = 0.0
	queue_redraw()


func get_light_radius() -> float:
	return RADIUS


func _process(delta: float) -> void:
	pulse_time += delta * (5.0 if is_active else 2.0)
	queue_redraw()


func _draw() -> void:
	var color := ACTIVE_COLOR if is_active else INACTIVE_COLOR
	var pulse := 0.5 + 0.5 * sin(pulse_time)
	var glow_alpha := 0.18 + pulse * 0.18
	var shard = PackedVector2Array([
		Vector2(0.0, -RADIUS - 6.0),
		Vector2(RADIUS * 0.78, 0.0),
		Vector2(0.0, RADIUS + 6.0),
		Vector2(-RADIUS * 0.78, 0.0),
	])
	var outline = PackedVector2Array([
		shard[0],
		shard[1],
		shard[2],
		shard[3],
	])
	outline.append(shard[0])

	draw_circle(Vector2.ZERO, RADIUS + 16.0 + pulse * 5.0, Color(color.r, color.g, color.b, glow_alpha))
	draw_colored_polygon(shard, color)
	draw_polyline(outline, CORE_COLOR, 2.0)
	draw_line(Vector2(0.0, -RADIUS - 2.0), Vector2(0.0, RADIUS + 2.0), Color(1.0, 1.0, 1.0, 0.35), 1.5)
	draw_line(Vector2(-RADIUS * 0.58, 0.0), Vector2(RADIUS * 0.58, 0.0), Color(1.0, 1.0, 1.0, 0.3), 1.5)

	if is_active:
		draw_arc(Vector2.ZERO, RADIUS + 16.0 + pulse * 4.0, 0.0, TAU, 64, Color(0.25, 1.0, 0.55, 0.65), 5.0)
		draw_arc(Vector2.ZERO, RADIUS + 30.0 - pulse * 6.0, 0.0, TAU, 64, Color(0.8, 1.0, 0.75, 0.28), 3.0)
