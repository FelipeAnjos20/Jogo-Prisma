extends AudioStreamPlayer

var music_enabled = true


func _ready() -> void:
	volume_db = -18.0
	autoplay = true

	if stream != null:
		_set_loop_if_available(stream)

	play()


func _set_loop_if_available(audio_stream: Resource) -> void:
	for property in audio_stream.get_property_list():
		if property["name"] == "loop":
			audio_stream.set("loop", true)
		elif property["name"] == "loop_mode":
			audio_stream.set("loop_mode", 1)


func toggle_music() -> bool:
	music_enabled = not music_enabled
	stream_paused = not music_enabled

	if music_enabled and not playing:
		play()

	return music_enabled


func is_music_enabled() -> bool:
	return music_enabled and not stream_paused
