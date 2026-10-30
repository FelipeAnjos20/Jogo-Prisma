extends Node2D

# Cristal receptor. Acende enquanto recebe luz da cor exigida ("any" aceita qualquer cor).

const UI := preload("res://scripts/ui_kit.gd")
const RADIUS := 28.0

var required_color := "any"
var is_lit := false

var _time := 0.0
var _glow := 0.0
var _burst := 0.0
var _particles: Array = []


func configure(data: Dictionary) -> void:
	position = data["position"]
	required_color = data["color"]
	is_lit = false
	_glow = 0.0
	_burst = 0.0
	_particles.clear()
	_time = randf() * 10.0


func get_light_radius() -> float:
	return RADIUS


func accepts(light_color_name: String) -> bool:
	return required_color == "any" or required_color == light_color_name


func set_lit(value: bool) -> void:
	if value and not is_lit:
		_burst = 1.0
		_spawn_particles()
	is_lit = value


func _spawn_particles() -> void:
	for i in range(22):
		var angle := randf() * TAU
		var speed := randf_range(90.0, 220.0)
		_particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.5, 0.9),
			"age": 0.0,
		})


func _process(delta: float) -> void:
	_time += delta
	_glow = move_toward(_glow, 1.0 if is_lit else 0.0, delta * 4.0)
	_burst = maxf(0.0, _burst - delta * 1.4)

	for particle in _particles:
		particle["age"] += delta
		particle["position"] += particle["velocity"] * delta
		particle["velocity"] *= 0.94
	_particles = _particles.filter(func(p: Dictionary) -> bool: return p["age"] < p["life"])

	queue_redraw()


func _draw() -> void:
	var base := UI.light_color(required_color)
	var pulse := 0.5 + 0.5 * sin(_time * (5.0 if is_lit else 1.8))
	var bob := sin(_time * 1.6) * 3.0 * (1.0 - _glow * 0.5)
	var dim := base.darkened(0.55)
	var color := dim.lerp(base, _glow)

	# Pedestal.
	draw_set_transform(Vector2(0, RADIUS + 14), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(Vector2.ZERO, RADIUS, Color(color.r, color.g, color.b, 0.25 + _glow * 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Aura.
	var aura := 0.1 + pulse * 0.08 + _glow * 0.25
	draw_circle(Vector2(0, bob), RADIUS + 22.0 + pulse * 6.0, Color(color.r, color.g, color.b, aura * 0.5))
	draw_circle(Vector2(0, bob), RADIUS + 10.0, Color(color.r, color.g, color.b, aura))

	# Raios girando quando aceso.
	if _glow > 0.01:
		for i in range(8):
			var angle := _time * 0.9 + i * TAU / 8.0
			var direction := Vector2(cos(angle), sin(angle))
			draw_line(Vector2(0, bob) + direction * (RADIUS + 6.0), Vector2(0, bob) + direction * (RADIUS + 26.0 + pulse * 8.0), Color(color.r, color.g, color.b, 0.45 * _glow), 3.0, true)

	# Gema facetada.
	var top := Vector2(0, -RADIUS - 8 + bob)
	var right := Vector2(RADIUS * 0.82, -4 + bob)
	var bottom := Vector2(0, RADIUS + 6 + bob)
	var left := Vector2(-RADIUS * 0.82, -4 + bob)
	var core := Vector2(0, -6 + bob)
	var light_face := color.lightened(0.45)
	var mid_face := color
	var dark_face := color.darkened(0.35)
	draw_colored_polygon(PackedVector2Array([top, right, core]), light_face)
	draw_colored_polygon(PackedVector2Array([top, core, left]), mid_face.lightened(0.15))
	draw_colored_polygon(PackedVector2Array([left, core, bottom]), dark_face)
	draw_colored_polygon(PackedVector2Array([core, right, bottom]), mid_face)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), Color(1, 1, 1, 0.55 + _glow * 0.4), 2.0, true)
	draw_line(top, core, Color(1, 1, 1, 0.35), 1.0, true)
	draw_line(left, core, Color(1, 1, 1, 0.25), 1.0, true)
	draw_line(right, core, Color(1, 1, 1, 0.25), 1.0, true)

	# Brilho estrela.
	var sparkle := Vector2(-8, -14 + bob)
	var sparkle_size := 4.0 + pulse * 3.0
	draw_line(sparkle - Vector2(sparkle_size, 0), sparkle + Vector2(sparkle_size, 0), Color(1, 1, 1, 0.8), 1.5, true)
	draw_line(sparkle - Vector2(0, sparkle_size), sparkle + Vector2(0, sparkle_size), Color(1, 1, 1, 0.8), 1.5, true)

	# Indicador da cor exigida: anel colorido + simbolo da cor (acessibilidade).
	if required_color != "any":
		draw_arc(Vector2(0, bob), RADIUS + 12.0, 0.0, TAU, 48, Color(base.r, base.g, base.b, 0.8), 2.5, true)
		for i in range(6):
			var angle := i * TAU / 6.0 - _time * 0.5
			draw_circle(Vector2(0, bob) + Vector2(cos(angle), sin(angle)) * (RADIUS + 12.0), 3.0, base.lightened(0.3))
		var badge := Vector2(RADIUS + 10.0, -RADIUS - 6.0 + bob)
		draw_circle(badge, 11.0, Color(0.04, 0.06, 0.12, 0.95))
		draw_circle(badge, 11.0, Color(base.r, base.g, base.b, 0.9), false, 1.5, true)
		UI.draw_color_symbol(self, badge, 6.5, required_color, base)

	# Onda de choque ao acender.
	if _burst > 0.0:
		var progress := 1.0 - _burst
		draw_arc(Vector2(0, bob), RADIUS + 10.0 + progress * 90.0, 0.0, TAU, 64, Color(base.r, base.g, base.b, _burst * 0.8), 4.0 * _burst + 1.0, true)
		draw_circle(Vector2(0, bob), RADIUS + 16.0, Color(1, 1, 1, _burst * 0.35))

	for particle in _particles:
		var fade := 1.0 - float(particle["age"]) / float(particle["life"])
		var position_p: Vector2 = particle["position"] + Vector2(0, bob)
		draw_circle(position_p, 2.5 * fade + 0.5, Color(base.r, base.g, base.b, fade).lightened(0.3))
