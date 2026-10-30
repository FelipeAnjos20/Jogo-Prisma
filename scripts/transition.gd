extends CanvasLayer

# Autoload: fade suave entre cenas e entre fases.

const FADE_OUT_TIME := 0.25
const FADE_IN_TIME := 0.32

var _curtain: ColorRect
var _busy := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_curtain = ColorRect.new()
	_curtain.color = Color(0.01, 0.015, 0.035, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)


func is_busy() -> bool:
	return _busy


func go_to(scene_path: String) -> void:
	fade_call(_change_scene.bind(scene_path))


func _change_scene(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


func fade_call(action: Callable) -> void:
	if _busy:
		return
	_busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out := create_tween()
	fade_out.tween_property(_curtain, "color:a", 1.0, FADE_OUT_TIME)
	await fade_out.finished

	action.call()
	await get_tree().process_frame
	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_property(_curtain, "color:a", 0.0, FADE_IN_TIME)
	await fade_in.finished

	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
