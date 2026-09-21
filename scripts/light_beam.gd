extends Node2D

signal crystal_activated

@export var emitter_path: NodePath
@export var max_distance = 1800.0
@export var max_reflections = 5

var beam_points = []
var hit_points = []
var crystal_was_hit = false
var pulse_offset = 0.0
var beam_line = null

const BEAM_CORE_COLOR = Color(1.0, 1.0, 0.1, 1.0)
const BEAM_REFLECTED_COLOR = Color(0.0, 1.0, 1.0, 1.0)
const BEAM_GLOW_COLOR = Color(1.0, 0.55, 0.0, 0.28)
const PULSE_COLOR = Color(1.0, 1.0, 1.0, 1.0)
const PULSE_SPEED = 420.0
const PULSE_SPACING = 95.0
const RAY_SURFACE_OFFSET = 2.0
const MIN_HIT_DISTANCE = 0.5


func _ready() -> void:
	z_index = 100
	beam_line = get_node_or_null("BeamLine")
	recalculate_beam()


func _process(delta: float) -> void:
	pulse_offset = fmod(pulse_offset + PULSE_SPEED * delta, PULSE_SPACING)
	recalculate_beam()


func recalculate_beam() -> void:
	var emitter = _get_emitter()
	if emitter == null:
		_draw_fallback_beam()
		return

	beam_points.clear()
	hit_points.clear()

	var origin = emitter.global_position
	var direction = Vector2.RIGHT.rotated(emitter.global_rotation).normalized()
	var hit_crystal = false
	var ignored_mirror = null

	beam_points.append(origin)

	for bounce_index in range(max_reflections + 1):
		var result = _cast_light_ray(origin, direction, ignored_mirror)

		if result.is_empty():
			beam_points.append(origin + direction * max_distance)
			break

		var hit_position = result["position"]
		var collider = result["collider"]

		beam_points.append(hit_position)
		hit_points.append(hit_position)

		if result["type"] == "crystal" and collider != null and collider.has_method("activate_from_light"):
			collider.activate_from_light()
			hit_crystal = true
			break

		if result["type"] == "mirror" and collider != null:
			var normal = collider.get_light_normal(direction)
			direction = direction.bounce(normal).normalized()
			origin = hit_position + direction * RAY_SURFACE_OFFSET
			ignored_mirror = collider
			continue

		break

	if hit_crystal and not crystal_was_hit:
		crystal_activated.emit()

	crystal_was_hit = hit_crystal
	_update_beam_line()
	queue_redraw()


func _cast_light_ray(origin: Vector2, direction: Vector2, ignored_mirror) -> Dictionary:
	var closest = {
		"distance": max_distance,
		"position": origin + direction * max_distance,
		"collider": null,
		"type": "none",
	}

	for mirror in _get_mirrors():
		if mirror == ignored_mirror:
			continue

		if not mirror.is_active:
			continue

		var segment = mirror.get_light_segment()
		var mirror_hit = _intersect_ray_segment(origin, direction, segment[0], segment[1])

		if not mirror_hit.is_empty() and mirror_hit["distance"] < closest["distance"]:
			closest = {
				"distance": mirror_hit["distance"],
				"position": mirror_hit["position"],
				"collider": mirror,
				"type": "mirror",
			}

	for obstacle in _get_obstacles():
		if not obstacle.is_active:
			continue

		for edge in obstacle.get_light_edges():
			var obstacle_hit = _intersect_ray_segment(origin, direction, edge[0], edge[1])

			if not obstacle_hit.is_empty() and obstacle_hit["distance"] < closest["distance"]:
				closest = {
					"distance": obstacle_hit["distance"],
					"position": obstacle_hit["position"],
					"collider": obstacle,
					"type": "obstacle",
				}

	var crystal = _get_crystal()
	if crystal != null:
		var radius = crystal.get_light_radius()
		var crystal_hit = _intersect_ray_circle(origin, direction, crystal.global_position, radius)

		if not crystal_hit.is_empty() and crystal_hit["distance"] < closest["distance"]:
			closest = {
				"distance": crystal_hit["distance"],
				"position": crystal_hit["position"],
				"collider": crystal,
				"type": "crystal",
			}

	if closest["type"] == "none":
		return {}

	return closest


func _intersect_ray_segment(origin: Vector2, direction: Vector2, start: Vector2, end: Vector2) -> Dictionary:
	var segment = end - start
	var divisor = direction.cross(segment)

	if abs(divisor) < 0.0001:
		return {}

	var origin_to_start = start - origin
	var distance = origin_to_start.cross(segment) / divisor
	var segment_position = origin_to_start.cross(direction) / divisor

	if distance <= MIN_HIT_DISTANCE:
		return {}

	if segment_position < 0.0 or segment_position > 1.0:
		return {}

	return {
		"distance": distance,
		"position": origin + direction * distance,
	}


func _intersect_ray_circle(origin: Vector2, direction: Vector2, center: Vector2, radius: float) -> Dictionary:
	var origin_to_center = origin - center
	var b = 2.0 * origin_to_center.dot(direction)
	var c = origin_to_center.dot(origin_to_center) - radius * radius
	var discriminant = b * b - 4.0 * c

	if discriminant < 0.0:
		return {}

	var root = sqrt(discriminant)
	var first_distance = (-b - root) * 0.5
	var second_distance = (-b + root) * 0.5
	var distance = first_distance if first_distance > MIN_HIT_DISTANCE else second_distance

	if distance <= MIN_HIT_DISTANCE:
		return {}

	return {
		"distance": distance,
		"position": origin + direction * distance,
	}


func _get_mirrors() -> Array:
	var parent = get_parent()
	if parent == null:
		return []

	var mirrors_node = parent.get_node_or_null("Mirrors")
	if mirrors_node == null:
		return []

	return mirrors_node.get_children()


func _get_obstacles() -> Array:
	var parent = get_parent()
	if parent == null:
		return []

	var obstacles_node = parent.get_node_or_null("Obstacles")
	if obstacles_node == null:
		return []

	return obstacles_node.get_children()


func _get_crystal():
	var parent = get_parent()
	if parent == null:
		return null

	return parent.get_node_or_null("Crystal")


func _get_emitter():
	var emitter = get_node_or_null(emitter_path)

	if emitter != null:
		return emitter

	var parent = get_parent()
	if parent != null:
		emitter = parent.get_node_or_null("Emitter")

	return emitter


func _draw_fallback_beam() -> void:
	beam_points.clear()
	hit_points.clear()
	beam_points.append(Vector2(120.0, 360.0))
	beam_points.append(Vector2(980.0, 360.0))
	_update_beam_line()
	queue_redraw()


func _update_beam_line() -> void:
	if beam_line == null:
		return

	beam_line.clear_points()

	for point in beam_points:
		beam_line.add_point(to_local(point))


func _draw() -> void:
	if beam_points.size() < 2:
		return

	for index in range(beam_points.size() - 1):
		var start = to_local(beam_points[index])
		var end = to_local(beam_points[index + 1])
		var color = BEAM_CORE_COLOR

		if index > 0:
			color = BEAM_REFLECTED_COLOR

		draw_line(start, end, BEAM_GLOW_COLOR, 22.0)
		draw_line(start, end, Color(color.r, color.g, color.b, 0.45), 12.0)
		draw_line(start, end, color, 5.0)
		_draw_direction_arrow(start, end, color)

	_draw_light_pulses()
	_draw_hit_marks()


func _draw_direction_arrow(start: Vector2, end: Vector2, color: Color) -> void:
	var length = start.distance_to(end)
	if length < 70.0:
		return

	var direction = (end - start).normalized()
	var side = Vector2(-direction.y, direction.x)
	var center = start.lerp(end, 0.65)
	var tip = center + direction * 20.0
	var left = center - direction * 12.0 + side * 9.0
	var right = center - direction * 12.0 - side * 9.0

	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)


func _draw_light_pulses() -> void:
	var total_length = _get_total_beam_length()
	var distance = pulse_offset

	while distance < total_length:
		var point = to_local(_get_global_point_at_distance(distance))
		draw_circle(point, 10.0, Color(1.0, 1.0, 1.0, 0.35))
		draw_circle(point, 5.0, PULSE_COLOR)
		distance += PULSE_SPACING


func _draw_hit_marks() -> void:
	for point in hit_points:
		var local_point = to_local(point)
		draw_circle(local_point, 9.0, Color(1.0, 1.0, 1.0, 1.0))
		draw_circle(local_point, 5.0, Color(1.0, 0.35, 0.0, 1.0))


func _get_total_beam_length() -> float:
	var total = 0.0

	for index in range(beam_points.size() - 1):
		total += beam_points[index].distance_to(beam_points[index + 1])

	return total


func _get_global_point_at_distance(distance: float) -> Vector2:
	var remaining = distance

	for index in range(beam_points.size() - 1):
		var start = beam_points[index]
		var end = beam_points[index + 1]
		var segment_length = start.distance_to(end)

		if remaining <= segment_length:
			return start.lerp(end, remaining / max(segment_length, 0.001))

		remaining -= segment_length

	return beam_points[beam_points.size() - 1]
