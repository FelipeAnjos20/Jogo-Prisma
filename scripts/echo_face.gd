extends Control

# Rosto do Echo, desenhado por codigo. Usado no aviso de fala, no painel de vitoria,
# no Echo da barra superior (clicavel) e nas telas do menu.
# Expressoes: neutral, happy, thinking, surprised, sleepy. "talking" faz o Echo pulsar enquanto fala.

const UI := preload("res://scripts/ui_kit.gd")

var mood := "neutral"
var talking := false
# O olho acompanha o ponteiro do mouse.
var follow_mouse := true
var radius := 16.0

var _time := 0.0
var _pupil := Vector2(1.5, 0.0)


func _init(body_radius := 16.0) -> void:
	radius = body_radius
	custom_minimum_size = Vector2.ONE * body_radius * 2.9
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	var target := Vector2(1.5, 0.0)
	if mood == "thinking":
		target = Vector2(2.5, -2.5)
	elif follow_mouse and is_visible_in_tree():
		var to_mouse := get_local_mouse_position() - size * 0.5
		target = to_mouse.limit_length(60.0) / 60.0 * 3.2
	_pupil = _pupil.lerp(target, minf(1.0, delta * 10.0))
	queue_redraw()


func _draw() -> void:
	var k := radius / 16.0
	var bounce_speed := 6.0 if mood == "happy" else (1.2 if mood == "sleepy" else 2.4)
	var center := size * 0.5 + Vector2(0, sin(_time * bounce_speed) * 2.0 * k)
	var pulse := 0.5 + 0.5 * sin(_time * (14.0 if talking else 3.0))
	var glow := Color(0.3, 0.8, 1.0)
	match mood:
		"happy":
			glow = Color(0.5, 1.0, 0.6)
		"thinking":
			glow = Color(1.0, 0.85, 0.4)
		"surprised":
			glow = Color(1.0, 0.55, 0.6)
		"sleepy":
			glow = Color(0.6, 0.62, 1.0)
	var eye_color := Color(0.85, 1.0, 1.0)
	draw_circle(center, 22.0 * k, Color(glow.r, glow.g, glow.b, 0.12 + pulse * 0.1))
	draw_circle(center, 16.0 * k, Color(0.12, 0.3, 0.5))
	draw_circle(center, 16.0 * k, glow.lightened(0.3), false, 2.0, true)

	if mood == "happy":
		# Olho sorrindo (arco para cima).
		draw_arc(center + Vector2(0, 3) * k, 6.0 * k, PI * 1.1, PI * 1.9, 12, eye_color, 3.0, true)
		return

	if mood == "sleepy":
		# Olho fechado e "Zzz" subindo.
		draw_arc(center + Vector2(0, -1) * k, 5.5 * k, PI * 0.15, PI * 0.85, 10, eye_color, 2.5, true)
		for i in range(2):
			var rise := fmod(_time * 0.6 + i * 0.5, 1.0)
			var spot := center + Vector2(12.0 + rise * 8.0 + i * 4.0, -12.0 - rise * 16.0) * k
			draw_string(UI.font(800), spot, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int((9.0 + i * 3.0) * k), Color(0.8, 0.85, 1.0, 1.0 - rise))
		return

	var eye_radius := (7.5 if mood == "surprised" else 6.0) * k
	if mood == "thinking":
		for i in range(3):
			var alpha := 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 4.0 - i))
			draw_circle(center + Vector2(10 + i * 6, -19) * k, 2.0 * k, Color(1.0, 0.9, 0.5, alpha))
	var blink := 0.15 if fmod(_time, 3.2) < 0.12 else 1.0
	draw_set_transform(center, 0.0, Vector2(1.0, blink))
	draw_circle(Vector2.ZERO, eye_radius, eye_color)
	draw_circle(_pupil * k, (2.0 if mood == "surprised" else 2.5) * k, Color(0.05, 0.15, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
