extends Node2D

# Arte animada do menu: raio de luz entrando no prisma e saindo como espectro.

@export var prism_size := 150.0
@export var beam_length := 520.0
@export var spectrum_length := 460.0

const SPECTRUM := [
	Color(1.0, 0.28, 0.32),
	Color(1.0, 0.58, 0.22),
	Color(1.0, 0.92, 0.3),
	Color(0.36, 1.0, 0.46),
	Color(0.3, 0.85, 1.0),
	Color(0.38, 0.5, 1.0),
	Color(0.72, 0.42, 1.0),
]

var time := 0.0

# Fragmentos do prisma: um por fase. Os ja recuperados brilham em cores do espectro.
@export var shard_count := 10
var shards_lit := 0


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var s := prism_size
	var top := Vector2(0, -s)
	var right := Vector2(s * 0.95, s * 0.72)
	var left := Vector2(-s * 0.95, s * 0.72)
	var entry := top.lerp(left, 0.52)
	var exit_point := top.lerp(right, 0.5)
	var breathe := 0.5 + 0.5 * sin(time * 1.5)

	# Halo.
	draw_circle(Vector2(0, 10), s * 1.5, Color(0.3, 0.25, 0.7, 0.05 + breathe * 0.03))
	draw_circle(Vector2(0, 10), s * 1.0, Color(0.35, 0.3, 0.8, 0.05))

	# Raio de entrada.
	var source := entry + Vector2(-beam_length, 30)
	_glow_line(source, entry, Color(1.0, 0.94, 0.7), 1.0)

	# Luz atravessando o vidro.
	_glow_line(entry, exit_point, Color(1.0, 1.0, 0.95), 0.6)

	# Espectro.
	for i in range(SPECTRUM.size()):
		var angle := deg_to_rad(-16.0 + i * 6.5 + sin(time * 0.7 + i * 0.4) * 0.6)
		var end := exit_point + Vector2(cos(angle), sin(angle)) * spectrum_length
		var shimmer := 0.75 + 0.25 * sin(time * 2.2 + i)
		_glow_line(exit_point, end, SPECTRUM[i], shimmer)

		# Pulsos viajando pelo raio.
		var travel := fmod(time * 0.35 + i * 0.13, 1.0)
		var pulse_point := exit_point.lerp(end, travel)
		draw_circle(pulse_point, 6.0, Color(SPECTRUM[i].r, SPECTRUM[i].g, SPECTRUM[i].b, 0.35 * (1.0 - travel)))

	# Corpo do prisma.
	var body := PackedVector2Array([top, right, left])
	draw_polygon(body, PackedColorArray([
		Color(0.45, 0.4, 0.95, 0.35),
		Color(0.2, 0.5, 0.8, 0.22),
		Color(0.5, 0.2, 0.6, 0.22),
	]))
	var inner := PackedVector2Array([top.lerp(Vector2(0, s * 0.15), 0.25), right.lerp(Vector2(0, s * 0.15), 0.25), left.lerp(Vector2(0, s * 0.15), 0.25)])
	draw_colored_polygon(inner, Color(0.6, 0.6, 1.0, 0.06))
	_draw_shards([top, right, left])
	draw_polyline(PackedVector2Array([top, right, left, top]), Color(0.72, 0.78, 1.0, 0.9), 3.0, true)
	draw_polyline(PackedVector2Array([top, right, left, top]), Color(0.6, 0.65, 1.0, 0.18), 12.0, true)

	# Reflexo que percorre a aresta.
	var edge_t := fmod(time * 0.25, 1.0)
	draw_circle(top.lerp(right, edge_t), 5.0, Color(1, 1, 1, 0.5))
	draw_circle(entry, 7.0 + breathe * 3.0, Color(1, 1, 0.9, 0.45))
	draw_circle(exit_point, 8.0 + breathe * 3.0, Color(1, 1, 1, 0.4))


func _draw_shards(corners: Array) -> void:
	# Divide o triangulo em fatias a partir do centro, com pontos igualmente espacados no perimetro.
	var center: Vector2 = (corners[0] + corners[1] + corners[2]) / 3.0
	var edge_lengths := []
	var perimeter := 0.0
	for i in range(3):
		var length: float = corners[i].distance_to(corners[(i + 1) % 3])
		edge_lengths.append(length)
		perimeter += length

	for shard in range(shard_count):
		var start_distance := perimeter * shard / shard_count
		var end_distance := perimeter * (shard + 1) / shard_count
		var polygon := PackedVector2Array([center, _point_on_perimeter(corners, edge_lengths, start_distance)])
		# Inclui os cantos que ficam dentro da fatia.
		var walked := 0.0
		for i in range(3):
			walked += edge_lengths[i]
			if walked > start_distance and walked < end_distance:
				polygon.append(corners[(i + 1) % 3])
		polygon.append(_point_on_perimeter(corners, edge_lengths, end_distance))

		if shard < shards_lit:
			var hue := float(shard) / float(shard_count)
			var glow := 0.22 + 0.1 * sin(time * 2.0 + shard)
			draw_colored_polygon(polygon, Color.from_hsv(hue, 0.6, 1.0, glow))
		var edge := PackedVector2Array([polygon[0], polygon[1]])
		draw_polyline(edge, Color(0.75, 0.8, 1.0, 0.18), 1.0, true)


func _point_on_perimeter(corners: Array, edge_lengths: Array, distance: float) -> Vector2:
	var remaining := distance
	for i in range(3):
		var length: float = edge_lengths[i]
		if remaining <= length:
			return corners[i].lerp(corners[(i + 1) % 3], remaining / length)
		remaining -= length
	return corners[0]


func _glow_line(start: Vector2, end: Vector2, color: Color, strength: float) -> void:
	draw_line(start, end, Color(color.r, color.g, color.b, 0.06 * strength), 28.0, true)
	draw_line(start, end, Color(color.r, color.g, color.b, 0.16 * strength), 12.0, true)
	draw_line(start, end, Color(color.r, color.g, color.b, 0.7 * strength), 4.0, true)
	draw_line(start, end, Color(1, 1, 1, 0.5 * strength), 1.5, true)
