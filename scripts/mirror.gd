extends StaticBody2D

signal selected(mirror: Node)
signal rotated(mirror: Node)

@export var rotate_step_degrees := 15.0

var is_selected := false
var initial_rotation := 0.0
var can_rotate := true
var is_active := true

const MIRROR_SIZE = Vector2(120.0, 12.0)
const MIRROR_COLOR = Color(0.82, 0.92, 1.0)
const SELECTED_COLOR = Color(1.0, 0.86, 0.28)


func _ready() -> void:
	input_pickable = true
	initial_rotation = rotation
	queue_redraw()


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	# StaticBody2D receives mouse input through its CollisionShape2D.
	if is_active and can_rotate and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(self)


func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


func rotate_by_step(direction: int) -> void:
	if not is_active or not can_rotate:
		return

	rotation_degrees += rotate_step_degrees * float(direction)
	rotated.emit(self)
	queue_redraw()


func reset_mirror() -> void:
	rotation = initial_rotation
	set_selected(false)
	rotated.emit(self)


func configure(level_position: Vector2, level_rotation_degrees: float, level_can_rotate: bool, level_active: bool) -> void:
	position = level_position
	rotation_degrees = level_rotation_degrees
	initial_rotation = rotation
	can_rotate = level_can_rotate
	set_active(level_active)
	set_selected(false)


func set_active(value: bool) -> void:
	is_active = value
	visible = value
	input_pickable = value

	var shape = get_node_or_null("CollisionShape2D")
	if shape != null:
		shape.disabled = not value

	queue_redraw()


func contains_global_point(global_point: Vector2) -> bool:
	if not is_active or not can_rotate:
		return false

	var local_point := to_local(global_point)
	var click_area := Rect2(-MIRROR_SIZE * 0.5, MIRROR_SIZE).grow(14.0)
	return click_area.has_point(local_point)


func is_light_mirror() -> bool:
	return is_active


func get_light_normal(incoming_direction: Vector2) -> Vector2:
	var normal := Vector2.UP.rotated(global_rotation).normalized()

	if normal.dot(incoming_direction) > 0.0:
		normal = -normal

	return normal


func get_light_segment() -> PackedVector2Array:
	var half_length := MIRROR_SIZE.x * 0.5
	var local_start := Vector2(-half_length, 0.0)
	var local_end := Vector2(half_length, 0.0)
	return PackedVector2Array([to_global(local_start), to_global(local_end)])


func _draw() -> void:
	# The mirror is drawn by code so the prototype needs no art asset.
	var rect := Rect2(-MIRROR_SIZE * 0.5, MIRROR_SIZE)
	var color := SELECTED_COLOR if is_selected else MIRROR_COLOR

	if not can_rotate:
		color = Color(0.55, 0.72, 0.88)

	draw_rect(rect, color, true)
	draw_rect(rect, Color(0.08, 0.12, 0.18), false, 2.0)

	if is_selected:
		draw_rect(rect.grow(5.0), SELECTED_COLOR, false, 2.0)
