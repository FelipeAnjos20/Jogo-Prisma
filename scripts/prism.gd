extends Node2D

# Prisma: a luz branca que entra sai dividida em vermelho, verde e azul
# (em leque de 30 graus em relacao a direcao de entrada). Luz colorida atravessa reto.

const RADIUS := 30.0
const SPREAD_DEGREES := 30.0

const SPECTRUM := [Color(1.0, 0.3, 0.36), Color(0.34, 1.0, 0.5), Color(0.36, 0.62, 1.0)]

var energized := false
var _time := 0.0
var _energy := 0.0


func configure(data: Dictionary) -> void:
	position = data["position"]
	_time = randf() * 10.0


func get_light_radius() -> float:
	return RADIUS


func set_energized(value: bool) -> void:
	energized = value


func _process(delta: float) -> void:
	_time += delta
	_energy = move_toward(_energy, 1.0 if energized else 0.0, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 2.2)
	var size := RADIUS + 6.0
	var top := Vector2(0, -size)
	var right := Vector2(size * 0.9, size * 0.62)
	var left := Vector2(-size * 0.9, size * 0.62)

	# Aura arco-iris girando.
	for i in range(3):
		var angle := _time * 0.8 + i * TAU / 3.0
		var offset := Vector2(cos(angle), sin(angle)) * 6.0
		var color: Color = SPECTRUM[i]
		draw_circle(offset, RADIUS + 14.0 + pulse * 3.0, Color(color.r, color.g, color.b, 0.05 + _energy * 0.07))

	# Sombra e base.
	draw_colored_polygon(PackedVector2Array([top + Vector2(4, 6), right + Vector2(4, 6), left + Vector2(4, 6)]), Color(0, 0, 0, 0.35))

	# Corpo de vidro com gradiente.
	draw_polygon(PackedVector2Array([top, right, left]), PackedColorArray([
		Color(0.75, 0.75, 1.0, 0.55 + _energy * 0.2),
		Color(0.3, 0.55, 0.95, 0.4),
		Color(0.6, 0.3, 0.8, 0.4),
	]))

	# Faixas de espectro internas.
	for i in range(3):
		var t := 0.35 + i * 0.15
		var color: Color = SPECTRUM[i]
		var a := top.lerp(left, t)
		var b := top.lerp(right, t)
		draw_line(a, b, Color(color.r, color.g, color.b, 0.35 + _energy * 0.4), 2.0, true)

	var outline := PackedVector2Array([top, right, left, top])
	draw_polyline(outline, Color(0.85, 0.88, 1.0, 0.95), 2.5, true)
	draw_polyline(outline, Color(0.7, 0.75, 1.0, 0.15 + _energy * 0.2), 9.0, true)

	# Brilho percorrendo a aresta.
	var edge_t := fmod(_time * 0.35, 1.0)
	draw_circle(top.lerp(right, edge_t), 3.5, Color(1, 1, 1, 0.8))
	draw_circle(Vector2(0, 4), 4.0 + _energy * 3.0, Color(1, 1, 1, 0.35 + _energy * 0.5))
