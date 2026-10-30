extends CanvasLayer

# Autoload: iris de luz entre cenas e fases; fade com efeitos reduzidos.

const FADE_OUT_TIME := 0.25
const FADE_IN_TIME := 0.32
const IRIS_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform float progress = 0.0;
uniform vec2 screen_size = vec2(1280.0, 720.0);
uniform bool reduced = false;
void fragment() {
	vec3 dark = vec3(0.012, 0.018, 0.032);
	if (reduced) {
		COLOR = vec4(dark, progress);
	} else {
		float radius = mix(length(screen_size * 0.5) + 8.0, -8.0, progress);
		float distance_from_center = length((UV - vec2(0.5)) * screen_size);
		float cover = smoothstep(radius - 2.0, radius + 2.0, distance_from_center);
		float rim = exp(-abs(distance_from_center - radius) / 5.0);
		COLOR = vec4(dark + vec3(0.5, 0.43, 0.26) * rim, cover);
	}
}
"""

var _curtain: ColorRect
var _busy := false
var _iris_material: ShaderMaterial


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_curtain = ColorRect.new()
	_curtain.color = Color.WHITE
	var shader := Shader.new()
	shader.code = IRIS_SHADER
	_iris_material = ShaderMaterial.new()
	_iris_material.shader = shader
	_curtain.material = _iris_material
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)
	_curtain.resized.connect(_update_size)
	_update_size()
	_set_progress(0.0)
	_curtain.hide()


func _update_size() -> void:
	_iris_material.set_shader_parameter("screen_size", _curtain.size)


func _set_progress(value: float) -> void:
	_iris_material.set_shader_parameter("progress", value)


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
	var state := get_tree().root.get_node_or_null("GameState")
	_iris_material.set_shader_parameter("reduced", state != null and state.get("reduce_effects") == true)
	_curtain.show()
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out := create_tween()
	fade_out.tween_method(_set_progress, 0.0, 1.0, FADE_OUT_TIME).set_trans(Tween.TRANS_SINE)
	await fade_out.finished

	action.call()
	await get_tree().process_frame
	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_method(_set_progress, 1.0, 0.0, FADE_IN_TIME).set_trans(Tween.TRANS_SINE)
	await fade_in.finished

	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.hide()
	_busy = false
