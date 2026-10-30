extends Node2D

# Guia de angulos (parte educativa): para o espelho selecionado mostra
# - a inclinacao do espelho em relacao a horizontal (transferidor), e
# - em cada ponto onde a luz bate nele, a normal e os angulos de incidencia e de reflexao,
#   evidenciando que os dois sao sempre iguais (lei da reflexao).
# Liga/desliga com a tecla G ou em Opcoes.

const UI := preload("res://scripts/ui_kit.gd")
const Geometria = preload("res://scripts/geometria.gd")

const INCIDENCE_COLOR := Color(1.0, 0.8, 0.35)
const REFLECTION_COLOR := Color(0.45, 0.9, 1.0)
const NORMAL_LENGTH := 70.0
const ARC_RADIUS := 34.0

var _mirror: Node2D = null
var _reflections: Array = []
var _alpha := 0.0
var _enabled := true


func _ready() -> void:
	z_index = 40


func update_guide(mirror: Node2D, reflections: Array, enabled: bool) -> void:
	_mirror = mirror
	_enabled = enabled
	_reflections.clear()
	if mirror != null:
		for reflection in reflections:
			if reflection["mirror"] == mirror:
				_reflections.append(reflection)


func _process(delta: float) -> void:
	var visible_now := _enabled and _mirror != null and is_instance_valid(_mirror)
	_alpha = move_toward(_alpha, 1.0 if visible_now else 0.0, delta * 5.0)
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.01 or _mirror == null or not is_instance_valid(_mirror):
		return
	_draw_protractor()
	for reflection in _reflections:
		_draw_reflection(reflection)


func _draw_protractor() -> void:
	var center := to_local(_mirror.global_position)
	var inclination := Geometria.inclinacao_espelho(_mirror.rotation_degrees)
	var shown := int(round(inclination)) % 180
	var color := Color(1, 1, 1, 0.55 * _alpha)

	# Linha horizontal de referencia (0 grau) e arco ate o espelho.
	draw_dashed_line(center, center + Vector2(78, 0), color, 1.5, 6.0, true, true)
	if shown > 0:
		# Na tela o angulo matematico cresce para cima, entao o arco vai de 0 ate -inclinacao.
		var end_angle := -deg_to_rad(inclination)
		draw_arc(center, 46.0, end_angle, 0.0, 32, Color(1.0, 0.95, 0.7, 0.85 * _alpha), 2.0, true)
	# O rotulo fica na ponta da linha de referencia, longe do numero do espelho.
	_draw_tag(center + Vector2(122, 0), "θ = %d°" % shown, Color(1.0, 0.95, 0.7))


func _draw_reflection(reflection: Dictionary) -> void:
	var point := to_local(reflection["position"])
	var normal: Vector2 = reflection["normal"]
	var back_to_source: Vector2 = -(reflection["incoming"] as Vector2)
	var outgoing: Vector2 = reflection["outgoing"]
	var angle := int(round(float(reflection["angle"])))

	# Normal (perpendicular ao espelho) tracejada.
	draw_dashed_line(point, point + normal * NORMAL_LENGTH, Color(1, 1, 1, 0.75 * _alpha), 1.5, 5.0, true, true)
	draw_circle(point, 3.0, Color(1, 1, 1, 0.9 * _alpha))

	if angle <= 0:
		_draw_tag(point + normal * (NORMAL_LENGTH + 14.0), "i = r = 0°", Color.WHITE)
		return

	_draw_angle_arc(point, normal, back_to_source, INCIDENCE_COLOR, "i = %d°" % angle)
	_draw_angle_arc(point, normal, outgoing, REFLECTION_COLOR, "r = %d°" % angle)


func _draw_angle_arc(point: Vector2, normal: Vector2, direction: Vector2, color: Color, text: String) -> void:
	var start := normal.angle()
	var sweep := angle_difference(start, direction.angle())
	var faded := Color(color.r, color.g, color.b, 0.9 * _alpha)
	draw_arc(point, ARC_RADIUS, start, start + sweep, 24, faded, 3.0, true)
	var label_direction := Vector2.RIGHT.rotated(start + sweep * 0.5)
	_draw_tag(point + label_direction * (ARC_RADIUS + 26.0), text, color)


func _draw_tag(position_tag: Vector2, text: String, color: Color) -> void:
	var font := UI.font(800)
	var size := 15
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var box := Rect2(position_tag - Vector2(width * 0.5 + 6.0, 11.0), Vector2(width + 12.0, 21.0))
	draw_rect(box, Color(0.02, 0.04, 0.09, 0.85 * _alpha))
	draw_rect(box, Color(color.r, color.g, color.b, 0.7 * _alpha), false, 1.0)
	draw_string(font, Vector2(box.position.x + 6.0, box.position.y + 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color.r, color.g, color.b, _alpha))
