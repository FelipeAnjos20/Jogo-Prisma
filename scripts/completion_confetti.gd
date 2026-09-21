extends Node2D

var active := false
var pieces = []
var rng := RandomNumberGenerator.new()

const COLORS = [
	Color(1.0, 0.87, 0.25, 1.0),
	Color(0.42, 0.82, 1.0, 1.0),
	Color(0.36, 1.0, 0.56, 1.0),
	Color(1.0, 0.38, 0.5, 1.0),
	Color(0.75, 0.55, 1.0, 1.0),
]


func play() -> void:
	active = true
	visible = true
	pieces.clear()
	rng.randomize()

	for index in range(90):
		pieces.append({
			"position": Vector2(rng.randf_range(80.0, 1200.0), rng.randf_range(-220.0, 120.0)),
			"velocity": Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(70.0, 180.0)),
			"rotation": rng.randf_range(0.0, TAU),
			"spin": rng.randf_range(-5.0, 5.0),
			"size": rng.randf_range(5.0, 11.0),
			"color": COLORS[index % COLORS.size()],
		})

	queue_redraw()


func stop() -> void:
	active = false
	visible = false
	pieces.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return

	for piece in pieces:
		var position: Vector2 = piece["position"]
		var velocity: Vector2 = piece["velocity"]
		var rotation: float = piece["rotation"]
		var spin: float = piece["spin"]

		position += velocity * delta
		velocity.y += 120.0 * delta
		rotation += spin * delta

		if position.y > 780.0:
			position = Vector2(rng.randf_range(80.0, 1200.0), rng.randf_range(-180.0, -40.0))
			velocity = Vector2(rng.randf_range(-60.0, 60.0), rng.randf_range(75.0, 150.0))

		piece["position"] = position
		piece["velocity"] = velocity
		piece["rotation"] = rotation

	queue_redraw()


func _draw() -> void:
	if pieces.is_empty():
		return

	for piece in pieces:
		var center: Vector2 = piece["position"]
		var rotation: float = piece["rotation"]
		var direction := Vector2.RIGHT.rotated(rotation)
		var side := Vector2(-direction.y, direction.x)
		var half_length: float = piece["size"]
		var half_width: float = piece["size"] * 0.34
		var points = PackedVector2Array([
			center - direction * half_length - side * half_width,
			center + direction * half_length - side * half_width,
			center + direction * half_length + side * half_width,
			center - direction * half_length + side * half_width,
		])

		draw_colored_polygon(points, piece["color"])
