extends Node2D

# Tutorial da fase 1: seta animada apontando para o espelho, com a instrucao de como girar.
# Some sozinha no primeiro giro (main.gd chama dismiss()).

const UI := preload("res://scripts/ui_kit.gd")

var target: Node2D
var _time := 0.0
var _leaving := false


func _ready() -> void:
	z_index = 50
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)


func dismiss() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position
	queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 4.5) * 7.0
	var accent := UI.ACCENT

	# Seta vinda de baixo, apontando para o espelho.
	var tip := Vector2(0, 30 + bob)
	var tail := Vector2(0, 78 + bob)
	draw_line(tail, tip + Vector2(0, 10), Color(accent.r, accent.g, accent.b, 0.9), 5.0, true)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-12, 16), tip + Vector2(12, 16)]), accent)

	# Anel pulsando em volta do espelho.
	var ring := 0.5 + 0.5 * sin(_time * 3.0)
	draw_arc(Vector2.ZERO, 70.0 + ring * 8.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.25 + 0.2 * (1.0 - ring)), 2.0, true)

	# Instrucao.
	var font := UI.font(700)
	var text := "Arraste a ponta, use a roda do mouse ou aperte E"
	# A caixa acompanha a largura do texto (a fonte do navegador e mais larga que a do Windows).
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 32.0
	var box := Rect2(Vector2(-width * 0.5, 88 + bob), Vector2(width, 34))
	draw_rect(box, Color(0.04, 0.07, 0.13, 0.92))
	draw_rect(box, Color(accent.r, accent.g, accent.b, 0.8), false, 1.5)
	draw_string(font, box.position + Vector2(0, 23), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 16, Color(1.0, 0.96, 0.84))
