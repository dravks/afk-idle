extends Node
## Global ses motoru (autoload "AudioManager", class_name YOK: cakisma yapar).
## 2 BGM (crossfade) + 8 SFX havuzu + Master/BGM/SFX buslari.
## Dosya yoksa sessiz gecer (kayit basina bir kez bilgi basar, crash yok).

const POOL_SIZE := 8
const SFX_PATHS := ["res://assets/audio/sfx/%s.ogg", "res://assets/audio/sfx/%s.wav"]
const BGM_PATHS := ["res://assets/audio/bgm/%s.ogg", "res://assets/audio/bgm/%s.wav"]

var bgm_players: Array[AudioStreamPlayer] = []
var active_bgm_index: int = 0
var sfx_pool: Array[AudioStreamPlayer] = []
var audio_cache: Dictionary = {}

var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0

var _warned: Dictionary = {}
var _sfx_cursor: int = 0
var _bgm_tween: Tween

func _ready() -> void:
	_ensure_bus("BGM")
	_ensure_bus("SFX")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "BGM"
		add_child(p)
		bgm_players.append(p)
	for i in POOL_SIZE:
		var s := AudioStreamPlayer.new()
		s.bus = "SFX"
		add_child(s)
		sfx_pool.append(s)
	_apply_volumes()

func play_bgm(track_name: String, fade_duration: float = 1.0) -> void:
	if bgm_players.size() < 2:
		return
	var stream := _resolve_bgm(track_name)
	if stream == null:
		return
	var next := 1 - active_bgm_index
	var old: AudioStreamPlayer = bgm_players[active_bgm_index]
	var nxt: AudioStreamPlayer = bgm_players[next]
	active_bgm_index = next
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	if old.playing:
		_bgm_tween.tween_property(old, "volume_db", -60.0, fade_duration)
		_bgm_tween.chain().tween_callback(old.stop)
	nxt.stream = stream
	nxt.volume_db = -60.0
	nxt.play()
	_bgm_tween.tween_property(nxt, "volume_db", _db(bgm_volume), fade_duration)

func play_sfx(sound_name: String, pitch_range: float = 0.1) -> void:
	if sfx_pool.is_empty():
		return
	var stream := _resolve_sfx(sound_name)
	if stream == null:
		return
	var p := sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	p.volume_db = _db(sfx_volume)
	p.play()

func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var v := clampf(linear_volume, 0.0, 1.0)
	match bus_name:
		"Master":
			master_volume = v
		"BGM":
			bgm_volume = v
		"SFX":
			sfx_volume = v
		_:
			return
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, _db(v))

func _apply_volumes() -> void:
	for bus in ["Master", "BGM", "SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		if idx < 0:
			continue
		var v := master_volume
		if bus == "BGM":
			v = bgm_volume
		elif bus == "SFX":
			v = sfx_volume
		AudioServer.set_bus_volume_db(idx, _db(v))

func _db(linear: float) -> float:
	if linear <= 0.001:
		return -60.0
	return linear_to_db(linear)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

## Cozum sirasi: ogg -> wav -> sentetik. Hicbiri yoksa sessiz (bir kez bilgi).
func _resolve_sfx(sound_name: String) -> AudioStream:
	var key := "sfx:" + sound_name
	if audio_cache.has(key):
		return audio_cache[key] as AudioStream
	for pattern in SFX_PATHS:
		var path: String = pattern % sound_name
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream != null:
				audio_cache[key] = stream
				return stream
	var synth := AudioSynthFactory.make_sfx(sound_name)
	if synth != null:
		audio_cache[key] = synth
		return synth
	_note_missing(key, SFX_PATHS[0] % sound_name)
	return null

func _resolve_bgm(track_name: String) -> AudioStream:
	var key := "bgm:" + track_name
	if audio_cache.has(key):
		return audio_cache[key] as AudioStream
	for pattern in BGM_PATHS:
		var path: String = pattern % track_name
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream != null:
				audio_cache[key] = stream
				return stream
	var synth := AudioSynthFactory.make_bgm(track_name)
	if synth != null:
		audio_cache[key] = synth
		return synth
	_note_missing(key, BGM_PATHS[0] % track_name)
	return null

func _note_missing(key: String, path: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	print("[AudioManager] ses yok, atlaniyor: %s" % path)
