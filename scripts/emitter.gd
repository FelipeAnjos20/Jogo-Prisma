extends Node2D

# Emissor de luz: carcaca metalica com lente pulsante. O raio sai para a direita (+X local).

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.2)
	var warm := Color(1.0, 0.86, 0.45)

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
