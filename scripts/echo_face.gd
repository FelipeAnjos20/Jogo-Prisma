extends Control

# Rosto do Echo, desenhado por codigo. Usado no aviso de fala, no painel de vitoria,
# no Echo da barra superior (clicavel) e nas telas do menu.
# Expressoes: neutral, happy, thinking, surprised, sleepy. "talking" faz o Echo pulsar enquanto fala.

const UI := preload("res://scripts/ui_kit.gd")

# Cores do Echo liberadas pelas estrelas (ver scripts/conquistas.gd): [corpo, contorno].
const LOOKS := {
	"menta": [Color(0.08, 0.34, 0.3), Color(0.55, 1.0, 0.85)],
	"rosa": [Color(0.4, 0.13, 0.3), Color(1.0, 0.62, 0.86)],
	"violeta": [Color(0.24, 0.14, 0.45), Color(0.8, 0.68, 1.0)],
	"dourado": [Color(0.4, 0.28, 0.06), Color(1.0, 0.86, 0.42)],
}

var mood := "neutral"
# Vazio: usa o visual escolhido pelo jogador. Preenchido: previa no menu.
var preview_color := ""
var preview_accessory := ""
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
	var body := Color(0.12, 0.3, 0.5)
	var rim := glow.lightened(0.3)
	var look := _color_id()
	if LOOKS.has(look):
		body = LOOKS[look][0]
		rim = LOOKS[look][1]
	elif look == "arco_iris":
		body = Color.from_hsv(fmod(_time * 0.08, 1.0), 0.55, 0.42)
		rim = Color.from_hsv(fmod(_time * 0.08 + 0.15, 1.0), 0.45, 1.0)
	draw_circle(center, 22.0 * k, Color(glow.r, glow.g, glow.b, 0.12 + pulse * 0.1))
	draw_circle(center, 16.0 * k, body)
	draw_circle(center, 16.0 * k, rim, false, 2.0, true)
	_draw_accessory(center, k)

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


func _color_id() -> String:
	if preview_color != "":
		return preview_color
	return GameState.echo_color if _has_state() else "azul"


func _accessory_id() -> String:
	if preview_accessory != "":
		return preview_accessory
	return GameState.echo_accessory if _has_state() else "nenhum"


func _has_state() -> bool:
	return is_inside_tree() and get_tree().root.has_node("GameState")


# Acessorio por cima da cabeca (laco, chapeu de mago ou coroa).
func _draw_accessory(center: Vector2, k: float) -> void:
	match _accessory_id():
		"laco":
			var knot := center + Vector2(9, -13) * k
			var color := Color(1.0, 0.4, 0.55)
			draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(-8, -6) * k, knot + Vector2(-8, 5) * k]), color)
			draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(8, -6) * k, knot + Vector2(8, 5) * k]), color)
			draw_circle(knot, 2.5 * k, color.lightened(0.3))
		"chapeu":
			var base_left := center + Vector2(-13, -11) * k
			var base_right := center + Vector2(13, -11) * k
			var tip := center + Vector2(6, -36) * k
			draw_colored_polygon(PackedVector2Array([base_left, base_right, tip]), Color(0.32, 0.2, 0.62))
			draw_line(base_left + Vector2(-3, 0) * k, base_right + Vector2(3, 0) * k, Color(0.45, 0.32, 0.8), 3.0 * k, true)
			UI.draw_star(self, center + Vector2(2, -22) * k, 3.5 * k, true)
		"coroa":
			var y := -12.0
			var points := PackedVector2Array([
				center + Vector2(-11, y) * k, center + Vector2(-11, y - 9) * k, center + Vector2(-5.5, y - 4) * k,
				center + Vector2(0, y - 11) * k, center + Vector2(5.5, y - 4) * k, center + Vector2(11, y - 9) * k,
				center + Vector2(11, y) * k,
			])
			draw_colored_polygon(points, Color(1.0, 0.84, 0.3))
			points.append(points[0])
			draw_polyline(points, Color(1.0, 0.95, 0.7), 1.2, true)
			draw_circle(center + Vector2(0, y - 3) * k, 1.8 * k, Color(1.0, 0.35, 0.45))
