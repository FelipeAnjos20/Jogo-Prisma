extends Node

# Autoload: musica de fundo persistente entre cenas e efeitos sonoros
# sintetizados por codigo (os efeitos nao precisam de arquivos de audio).

const MIX_RATE := 22050
const VOICES := 10

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

var _music: AudioStreamPlayer
var _music_path := ""
var _music_tween: Tween
var _pending_music: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	for _index in range(VOICES):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_players.append(player)

	# Som curto de "fala" do Echo (tocado enquanto o texto e digitado).
	_streams["talk"] = _synth([[1050.0, 0.0, 0.03]], 0.035, "sine", 80.0, 0.09)
	_streams["hover"] = _synth([[1400.0, 0.0, 0.035]], 0.04, "sine", 60.0, 0.12)
	_streams["click"] = _synth([[900.0, 0.0, 0.05], [1350.0, 0.02, 0.05]], 0.08, "tri", 40.0, 0.35)
	_streams["select"] = _synth([[660.0, 0.0, 0.08], [990.0, 0.05, 0.1]], 0.16, "sine", 22.0, 0.35)
	_streams["rotate"] = _synth([[1250.0, 0.0, 0.045], [0.0, 0.0, 0.03]], 0.05, "tri", 70.0, 0.4)
	_streams["undo"] = _synth([[880.0, 0.0, 0.06], [587.0, 0.05, 0.08]], 0.14, "tri", 26.0, 0.32)
	_streams["locked"] = _synth([[150.0, 0.0, 0.16], [112.0, 0.07, 0.14]], 0.22, "square", 14.0, 0.22)
	_streams["crystal_on"] = _synth([[1046.5, 0.0, 0.6], [1568.0, 0.05, 0.55], [2093.0, 0.1, 0.5]], 0.7, "sine", 5.0, 0.28)
	_streams["crystal_off"] = _synth([[740.0, 0.0, 0.12], [523.0, 0.06, 0.14]], 0.2, "sine", 18.0, 0.18)
	_streams["hint"] = _synth([[784.0, 0.0, 0.18], [1175.0, 0.12, 0.25]], 0.4, "sine", 8.0, 0.25)
	_streams["win"] = _synth([
		[523.25, 0.0, 0.5], [659.25, 0.1, 0.5], [783.99, 0.2, 0.5],
		[1046.5, 0.32, 0.9], [1318.5, 0.32, 0.9], [1568.0, 0.44, 0.8],
	], 1.3, "sine", 3.5, 0.24)
	_streams["fanfare"] = _synth([
		[392.0, 0.0, 0.3], [523.25, 0.15, 0.3], [659.25, 0.3, 0.3], [783.99, 0.45, 0.4],
		[1046.5, 0.65, 1.2], [1318.5, 0.65, 1.2], [1568.0, 0.65, 1.2], [2093.0, 0.8, 1.0],
	], 2.0, "sine", 2.2, 0.2)


func play_music(path: String, volume_db := -12.0) -> void:
	# Se a mesma faixa ja estiver tocando, ela continua sem reiniciar.
	if path == _music_path and _music.playing:
		return

	var stream := load(path) as AudioStream
	if stream == null:
		return
	if "loop" in stream:
		stream.set("loop", true)
	_music_path = path

	_pending_music = stream
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, 0.35)
	_music_tween.tween_callback(_start_pending_music)
	_music_tween.tween_property(_music, "volume_db", volume_db, 0.9)


func _start_pending_music() -> void:
	_music.stream = _pending_music
	_pending_music = null
	_music.volume_db = -40.0
	_music.play()


func _exit_tree() -> void:
	_music.stop()
	_music.stream = null
	_pending_music = null


func play(sound_name: String, pitch := 1.0) -> void:
	if not _streams.has(sound_name):
		return

	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[sound_name]
	player.pitch_scale = pitch
	player.play()


# Nota de sino (cristal aceso). O som e gerado na primeira vez e guardado.
func play_tone(frequency: float) -> void:
	var key := "tone_%d" % int(frequency)
	if not _streams.has(key):
		_streams[key] = _synth([[frequency, 0.0, 0.9], [frequency * 2.0, 0.0, 0.45]], 1.0, "sine", 4.5, 0.24)
	play(key)


# Melodia de varias notas (ver scripts/musica.gd), gerada uma vez por chave.
func play_melody(key: String, notes: Array) -> void:
	if not _streams.has(key):
		var length := 0.0
		for note in notes:
			length = maxf(length, float(note[1]) + float(note[2]))
		_streams[key] = _synth(notes, length + 0.1, "sine", 3.5, 0.2)
	play(key)


# notes: lista de [frequencia, inicio, duracao]. Frequencia 0 gera ruido (estalo).
func _synth(notes: Array, length: float, wave: String, decay: float, volume: float) -> AudioStreamWAV:
	var count := int(length * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for note in notes:
		var frequency: float = note[0]
		var start := int(float(note[1]) * MIX_RATE)
		var duration := int(float(note[2]) * MIX_RATE)

		for i in range(duration):
			var index := start + i
			if index >= count:
				break

			var t := float(i) / MIX_RATE
			var envelope := minf(1.0, t * 250.0) * exp(-t * decay)
			var phase := TAU * frequency * t
			var value := 0.0

			if frequency <= 0.0:
				value = randf_range(-1.0, 1.0) * 0.5
			elif wave == "square":
				value = signf(sin(phase)) * 0.55
			elif wave == "tri":
				value = asin(sin(phase)) * 0.636
			else:
				value = sin(phase) + 0.22 * sin(phase * 2.0) + 0.08 * sin(phase * 3.0)

			samples[index] += value * envelope * volume

	# Pequeno fade-out para evitar estalos no final do som.
	var fade := mini(count, int(0.01 * MIX_RATE))
	for i in range(fade):
		samples[count - 1 - i] *= float(i) / float(fade)

	return _to_wav(samples)


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)

	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
