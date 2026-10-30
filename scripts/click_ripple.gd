extends Node2D

# Onda de luz que se espalha onde o jogador clica na sala vazia (so visual).

const LIFE := 0.7
const MAX_RIPPLES := 6

var _ripples: Array = []


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func spawn(point: Vector2, color: Color) -> void:
	if _ripples.size() >= MAX_RIPPLES:
		_ripples.pop_front()
	_ripples.append({"position": to_local(point), "age": 0.0, "color": color})


func _process(delta: float) -> void:
	for ripple in _ripples:
		ripple["age"] += delta
	_ripples = _ripples.filter(func(r: Dictionary) -> bool: return r["age"] < LIFE)
	queue_redraw()


func _draw() -> void:
	for ripple in _ripples:
		var t: float = ripple["age"] / LIFE
		var color: Color = ripple["color"]
		var fade := (1.0 - t) * (1.0 - t)
		draw_arc(ripple["position"], 8.0 + t * 70.0, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.9 * fade), 3.0, true)
		draw_arc(ripple["position"], 4.0 + t * 38.0, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.55 * fade), 2.0, true)
		draw_circle(ripple["position"], 5.0 * (1.0 - t), Color(1, 1, 1, 0.7 * fade))
