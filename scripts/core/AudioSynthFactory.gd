extends RefCounted
class_name AudioSynthFactory
## Prosedurel fantezi sesleri: diskte dosya yoksa AudioManager buradan calar.
## 16-bit mono 22050Hz; BGM'ler loop'lu. Uretim lazy (ilk isteniste) ve
## AudioManager cache'inde tutulur. Basinclar 0.9'u gecmez.

const RATE := 22050

static func make_sfx(sound_name: String) -> AudioStreamWAV:
	match sound_name:
		"hit":
			return _hit()
		"crit":
			return _crit()
		"ultimate":
			return _ultimate()
		"meteor", "spell_meteor":
			return _meteor()
		"coin", "coins":
			return _coin()
		"summon_reveal":
			return _arp([0.0, 4.0, 7.0, 12.0], 0.09, 0.5)
		"elite_shine":
			return _arp([12.0, 16.0, 19.0, 24.0], 0.12, 0.5)
		"card_flip":
			return _noise(0.09, 0.3, 30.0, 0.7)
		"victory":
			return _melody([[0.0, 0.12], [4.0, 0.12], [7.0, 0.12], [12.0, 0.25]], 0.5)
		"defeat":
			return _melody([[0.0, 0.2], [-3.0, 0.2], [-7.0, 0.35]], 0.5)
		"btn_click":
			return _tone(1800.0, 0.03, 0.25, 60.0)
		"boss_roar":
			return _roar()
		"spell_shield":
			return _shield()
	return null

static func make_bgm(track_name: String) -> AudioStreamWAV:
	match track_name:
		"lobby":
			return _bgm_calm()
		"battle":
			return _bgm_drive()
	return null

# ---------------------------------------------------------------- cekirdek

static func _s16(v: float) -> int:
	return clampi(int(v * 32767.0), -32768, 32767)

static func _finish(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size() / 2
	return w

static func _n(semitones_from_a4: float) -> float:
	return 440.0 * pow(2.0, semitones_from_a4 / 12.0)

static func _tone(freq: float, dur: float, vol: float, decay: float, slide_to: float = 0.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := freq if slide_to <= 0.0 else lerpf(freq, slide_to, t / dur)
		phase += TAU * f / RATE
		data.encode_s16(i * 2, _s16(sin(phase) * vol * exp(-decay * t)))
	return _finish(data)

static func _noise(dur: float, vol: float, decay: float, smooth: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		prev = lerpf(prev, randf_range(-1.0, 1.0), 1.0 - smooth)
		data.encode_s16(i * 2, _s16(prev * vol * exp(-decay * t)))
	return _finish(data)

static func _mix(a: AudioStreamWAV, b: AudioStreamWAV, loop: bool = false) -> AudioStreamWAV:
	var da := a.data
	var db := b.data
	var n := maxi(da.size(), db.size()) / 2
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var va := 0
		var vb := 0
		if i * 2 + 1 < da.size():
			va = da.decode_s16(i * 2)
		if i * 2 + 1 < db.size():
			vb = db.decode_s16(i * 2)
		data.encode_s16(i * 2, clampi(va + vb, -32768, 32767))
	return _finish(data, loop)

static func _melody(notes: Array, vol: float) -> AudioStreamWAV:
	# notes: [yarimton, sure] ciftleri (A4 = 0).
	var data := PackedByteArray()
	for note in notes:
		var f := _n(float(note[0]))
		var dur := float(note[1])
		var n := int(dur * RATE)
		var base := data.size()
		data.resize(data.size() + n * 2)
		var phase := 0.0
		for i in n:
			var t := float(i) / RATE
			phase += TAU * f / RATE
			var s := sin(phase) + 0.3 * sin(phase * 2.0)
			data.encode_s16(base + i * 2, _s16(s * vol * 0.7 * exp(-3.0 * t)))
	return _finish(data)

static func _arp(semitones: Array, note_dur: float, vol: float) -> AudioStreamWAV:
	var notes: Array = []
	for s in semitones:
		notes.append([float(s), note_dur])
	return _melody(notes, vol)

# ---------------------------------------------------------------- sfx

static func _hit() -> AudioStreamWAV:
	var thump := _tone(120.0, 0.08, 0.9, 55.0)
	var snap := _noise(0.05, 0.5, 70.0, 0.2)
	return _mix(thump, snap)

static func _crit() -> AudioStreamWAV:
	var n := int(0.3 * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * 180.0 * t) * 0.6 + sin(TAU * 271.0 * t) * 0.4
		if i < int(0.03 * RATE):
			s += randf_range(-0.5, 0.5)
		data.encode_s16(i * 2, _s16(s * 0.85 * exp(-9.0 * t)))
	return _finish(data)

static func _ultimate() -> AudioStreamWAV:
	return _tone(300.0, 0.5, 0.6, 4.0, 1200.0)

static func _meteor() -> AudioStreamWAV:
	var boom := _noise(0.6, 0.9, 4.0, 0.85)
	var drop := _tone(150.0, 0.6, 0.7, 5.0, 40.0)
	return _mix(boom, drop)

static func _coin() -> AudioStreamWAV:
	var data := PackedByteArray()
	var parts := [[1568.0, 0.07], [2093.0, 0.14]]
	for part in parts:
		var f := float(part[0])
		var n := int(float(part[1]) * RATE)
		var base := data.size()
		data.resize(data.size() + n * 2)
		var phase := 0.0
		for i in n:
			var t := float(i) / RATE
			phase += TAU * f / RATE
			data.encode_s16(base + i * 2, _s16(sin(phase) * 0.55 * exp(-14.0 * t)))
	return _finish(data)

static func _roar() -> AudioStreamWAV:
	var n := int(0.8 * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var wobble := 1.0 + 0.15 * sin(TAU * 8.0 * t)
		var s := sin(TAU * 70.0 * wobble * t) * 0.6 + sin(TAU * 105.0 * wobble * t) * 0.4
		s += randf_range(-0.15, 0.15)
		data.encode_s16(i * 2, _s16(s * 0.7 * exp(-2.5 * t)))
	return _finish(data)

static func _shield() -> AudioStreamWAV:
	var n := int(0.25 * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * 880.0 * t) * 0.6 + sin(TAU * 1320.0 * t) * 0.4
		data.encode_s16(i * 2, _s16(s * 0.6 * exp(-12.0 * t)))
	return _finish(data)

# ---------------------------------------------------------------- bgm (8sn looplar)

static func _pad_chord(root: float, dur: float, vol: float) -> AudioStreamWAV:
	var partials := [1.0, 1.25, 1.5]
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for p in partials:
			s += sin(TAU * root * float(p) * t) / 3.0
		var attack := minf(1.0, t / 0.3)
		var release := minf(1.0, (dur - t) / 0.4)
		data.encode_s16(i * 2, _s16(s * vol * attack * release))
	return _finish(data)

static func _concat(parts: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for part in parts:
		data.append_array((part as AudioStreamWAV).data)
	return _finish(data, true)

static func _bgm_calm() -> AudioStreamWAV:
	# Am - F - C - G, yumusak pad (dongu basi/sonu soluklu).
	return _concat([
		_pad_chord(110.0, 2.0, 0.35),
		_pad_chord(87.31, 2.0, 0.35),
		_pad_chord(130.81, 2.0, 0.35),
		_pad_chord(98.0, 2.0, 0.35),
	])

static func _bgm_drive() -> AudioStreamWAV:
	# Bass nabzi + tiz arp (dongulu).
	var bass_notes := [55.0, 55.0, 65.41, 49.0]
	var bass_parts: Array = []
	for f in bass_notes:
		bass_parts.append(_bass_bar(float(f)))
	var bass := _concat(bass_parts)
	var arp := _arp_loop()
	return _mix(bass, arp, true)

static func _bass_bar(freq: float) -> AudioStreamWAV:
	var n := int(2.0 * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var step := int(0.25 * RATE)  # 8'lik nabiz
	for i in n:
		var t := float(i) / RATE
		var pos := i % step
		var tt := float(pos) / RATE
		var s := sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.3
		data.encode_s16(i * 2, _s16(s * 0.5 * exp(-6.0 * tt)))
	var w := _finish(data)
	return w

static func _arp_loop() -> AudioStreamWAV:
	var seq := [220.0, 261.63, 329.63, 261.63, 220.0, 196.0, 164.81, 196.0,
		174.61, 174.61, 196.0, 220.0, 196.0, 174.61, 164.81, 146.83]
	var data := PackedByteArray()
	var note_n := int(0.5 * RATE)
	for f in seq:
		var base := data.size()
		data.resize(data.size() + note_n * 2)
		var phase := 0.0
		for i in note_n:
			var t := float(i) / RATE
			phase += TAU * float(f) / RATE
			data.encode_s16(base + i * 2, _s16(sin(phase) * 0.22 * exp(-2.0 * t)))
	var w := _finish(data)
	return w
