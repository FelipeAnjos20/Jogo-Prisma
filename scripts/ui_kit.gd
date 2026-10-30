extends RefCounted

# Helpers visuais compartilhados: paleta, fontes e construcao de widgets.

const BG_DEEP := Color(0.012, 0.018, 0.04)
const PANEL_BG := Color(0.035, 0.055, 0.1, 0.92)
const PANEL_BORDER := Color(0.42, 0.72, 1.0, 0.4)
const TEXT := Color(0.88, 0.93, 1.0)
const TEXT_DIM := Color(0.6, 0.7, 0.85)
const ACCENT := Color(1.0, 0.86, 0.36)
const SUCCESS := Color(0.5, 1.0, 0.68)
const DANGER := Color(1.0, 0.36, 0.42)

const LIGHT_COLORS := {
	"white": Color(1.0, 0.93, 0.62),
	"red": Color(1.0, 0.3, 0.36),
	"green": Color(0.34, 1.0, 0.5),
	"blue": Color(0.36, 0.62, 1.0),
	"any": Color(0.62, 0.9, 1.0),
}

const COLOR_NAMES := {
	"red": "vermelho",
	"green": "verde",
	"blue": "azul",
}

# Atalhos do mouse/teclado na fase, liberados aos poucos: [primeira fase em que aparece, texto].
const ATALHOS := [
	[0, "Clique: selecionar"],
	[0, "Arrastar, Q/E ou roda: girar"],
	[0, "H: dica"],
	[1, "1-9 / Tab: trocar"],
	[1, "Z: desfazer"],
	[2, "T: falar com o Echo"],
	[2, "G: ângulos"],
	[3, "M: música"],
]

static var _fonts := {}


# Linha de atalhos da fase: so o que o jogador ja aprendeu, para nao encher a tela de texto.
static func atalhos_da_fase(index: int) -> String:
	var parts: Array = []
	for step in ATALHOS:
		if index >= int(step[0]):
			parts.append(step[1])
	return "   ·   ".join(parts)


static func light_color(color_name: String) -> Color:
	return LIGHT_COLORS.get(color_name, LIGHT_COLORS["white"])


static func font(weight := 500) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]

	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Segoe UI", "Bahnschrift", "Helvetica Neue", "Arial", "Sans-Serif"])
	system_font.font_weight = weight
	system_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	_fonts[weight] = system_font
	return system_font


static func label_settings(size: int, color: Color, weight := 500, outline := 0, outline_color := Color(0.0, 0.02, 0.05, 0.9)) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = font(weight)
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = outline
	settings.outline_color = outline_color
	return settings


static func make_label(text: String, size: int, color := TEXT, weight := 500, outline := 0) -> Label:
	var label := Label.new()
	label.text = text
	label.label_settings = label_settings(size, color, weight, outline)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func panel_style(bg := PANEL_BG, border := PANEL_BORDER, radius := 12, border_width := 1, margin := 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 12
	style.anti_aliasing = true
	return style


static func make_panel(bg := PANEL_BG, border := PANEL_BORDER, radius := 12, margin := 18) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style(bg, border, radius, 1, margin))
	return panel


static func make_button(text: String, font_size := 20, min_width := 0.0) -> Button:
	var button := Button.new()
	button.text = text
	# Foco permite navegar pelos menus com teclado/controle (o destaque so aparece nesse modo).
	button.focus_mode = Control.FOCUS_ALL
	button.focus_entered.connect(func() -> void:
		if button.get_viewport() != null and button.get_viewport().gui_get_focus_owner() == button and _pad_mode():
			play_sound("hover")
			_hover_effect(button, true)
	)
	button.focus_exited.connect(func() -> void: _hover_effect(button, false))
	button.add_theme_font_size_override("font_size", font_size)
	if min_width > 0.0:
		button.custom_minimum_size.x = min_width
	# O botao cresce a partir do centro.
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.mouse_entered.connect(func() -> void:
		play_sound("hover")
		_hover_effect(button, true)
	)
	button.mouse_exited.connect(func() -> void: _hover_effect(button, false))
	# Painel escondido com o mouse em cima: o botao volta ao normal.
	button.visibility_changed.connect(func() -> void:
		if not button.is_visible_in_tree():
			button.scale = Vector2.ONE
			button.modulate = Color.WHITE
	)
	button.pressed.connect(func() -> void:
		play_sound("click")
		_press_effect(button)
	)
	return button


# Botao com vida: cresce um pouco e brilha com o mouse em cima (ou com foco do teclado).
static func _hover_effect(button: Button, inside: bool) -> void:
	if not button.is_inside_tree():
		return
	var lit := inside and not button.disabled
	var tween := button.create_tween().set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE * (1.04 if lit else 1.0), 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.15, 1.12, 1.05) if lit else Color.WHITE, 0.14)


static func _press_effect(button: Button) -> void:
	if not button.is_inside_tree():
		return
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 0.96, 0.05)
	tween.tween_property(button, "scale", Vector2.ONE * (1.04 if button.is_hovered() else 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _pad_mode() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var state := tree.root.get_node_or_null("GameState")
	return state != null and bool(state.get("last_input_pad"))


static func play_sound(sound_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var sfx := tree.root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.play(sound_name)


# Acessibilidade: cada cor tambem tem uma forma (vermelho = triangulo, verde = circulo, azul = quadrado).
static func draw_color_symbol(canvas: CanvasItem, center: Vector2, radius: float, color_name: String, color: Color) -> void:
	var outline := Color(1, 1, 1, 0.9)
	match color_name:
		"red":
			var points := PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius * 0.95, radius * 0.72),
				center + Vector2(-radius * 0.95, radius * 0.72),
			])
			canvas.draw_colored_polygon(points, color)
			points.append(points[0])
			canvas.draw_polyline(points, outline, 1.2, true)
		"green":
			canvas.draw_circle(center, radius * 0.82, color)
			canvas.draw_circle(center, radius * 0.82, outline, false, 1.2, true)
		"blue":
			var square := Rect2(center - Vector2.ONE * radius * 0.72, Vector2.ONE * radius * 1.44)
			canvas.draw_rect(square, color)
			canvas.draw_rect(square, outline, false, 1.2)


static func star_points(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(10):
		var radius := outer_radius if i % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


static func draw_star(canvas: CanvasItem, center: Vector2, radius: float, filled: bool) -> void:
	if radius < 1.0:
		return
	var points := star_points(center, radius, radius * 0.45)
	if filled:
		canvas.draw_circle(center, radius * 1.25, Color(1.0, 0.8, 0.3, 0.14))
		canvas.draw_colored_polygon(points, ACCENT)
	else:
		canvas.draw_colored_polygon(points, Color(0.14, 0.18, 0.28, 0.9))
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, Color(1.0, 0.95, 0.75, 0.9) if filled else Color(0.4, 0.5, 0.65, 0.8), 1.5, true)
