extends Node2D

# Emissor de luz: carcaca metalica com lente pulsante. O raio sai para a direita (+X local).

var _time := 0.0
var _charge_left := 0.0


func charge() -> void:
	_charge_left = 0.3
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_charge_left = maxf(0.0, _charge_left - delta)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.2)
	var state := get_tree().root.get_node_or_null("GameState")
	var reduced: bool = state != null and state.get("reduce_effects") == true
	if reduced:
		pulse = 0.35
	var warm := Color(1.0, 0.86, 0.45)
	if _charge_left > 0.0 and not reduced:
		var charge_t := 1.0 - _charge_left / 0.3
		var strength := sin(charge_t * PI)
		draw_arc(Vector2(20, 0), lerpf(38.0, 17.0, charge_t), 0.0, TAU, 48, Color(1.0, 0.86, 0.45, strength * 0.65), 2.0, true)
		draw_circle(Vector2(20, 0), 30.0, Color(1.0, 0.86, 0.45, strength * 0.13))

	# Sombra e suporte.
	draw_rect(Rect2(-40, -22, 50, 50), Color(0.0, 0.0, 0.0, 0.3))
	draw_rect(Rect2(-24, 20, 20, 14), Color(0.1, 0.13, 0.2))

	# Carcaca.
	var body := Rect2(-44, -24, 52, 48)
	draw_rect(body, Color(0.13, 0.17, 0.26))
	draw_rect(Rect2(-44, -24, 52, 10), Color(0.2, 0.26, 0.38))
	draw_rect(body, Color(0.45, 0.6, 0.8, 0.8), false, 2.0)
	for i in range(3):
		draw_line(Vector2(-36 + i * 9, -8), Vector2(-36 + i * 9, 14), Color(0.05, 0.07, 0.12), 3.0)

	# Bocal e lente.
	draw_rect(Rect2(8, -16, 12, 32), Color(0.2, 0.26, 0.38))
	draw_rect(Rect2(8, -16, 12, 32), Color(0.45, 0.6, 0.8, 0.8), false, 1.5)
	draw_circle(Vector2(20, 0), 22.0 + pulse * 5.0, Color(warm.r, warm.g, warm.b, 0.12))
	draw_circle(Vector2(20, 0), 13.0, Color(warm.r, warm.g, warm.b, 0.35 + pulse * 0.2))
	draw_circle(Vector2(20, 0), 8.0, warm)
	draw_circle(Vector2(18, -2), 3.5, Color(1, 1, 1, 0.95))

	# Luz indicadora.
	draw_circle(Vector2(-30, -16), 3.0, Color(0.4, 1.0, 0.6, 0.6 + pulse * 0.4))
