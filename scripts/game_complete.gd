extends Node2D

@onready var prism: Node2D = $Prism
@onready var title_label: Label = $HUD/TitleLabel
@onready var subtitle_label: Label = $HUD/SubtitleLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var confetti: Node2D = $HUD/CompletionConfetti

var time := 0.0


func _ready() -> void:
	title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	title_label.scale = Vector2(0.72, 0.72)
	prism.scale = Vector2(0.8, 0.8)

	if confetti.has_method("play"):
		confetti.play()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(prism, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.35)
	tween.tween_property(title_label, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(subtitle_label, "modulate:a", 1.0, 0.45)
	tween.chain().tween_property(hint_label, "modulate:a", 1.0, 0.35)


func _process(delta: float) -> void:
	time += delta
	prism.rotation = sin(time * 0.9) * 0.08
	var hint_color := hint_label.modulate
	hint_color.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(time * 3.0))
	hint_label.modulate = hint_color


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
