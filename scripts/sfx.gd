class_name Sfx
extends Node

const RATE := 22050
const SFX_DB := -13.0
const LOOP_DB := -22.0

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var pool_index := 0
var loop_player: AudioStreamPlayer
var current_loop := ""
var enabled := true

func _ready() -> void:
	streams["waka_a"] = _tone([{"f0": 560.0, "f1": 210.0, "d": 0.085}], 0.30)
	streams["waka_b"] = _tone([{"f0": 210.0, "f1": 560.0, "d": 0.085}], 0.30)
	streams["pellet"] = _tone([{"f0": 320.0, "f1": 900.0, "d": 0.16}], 0.28)
	streams["ghost"] = _tone([{"f0": 90.0, "f1": 1100.0, "d": 0.40}], 0.32)
	streams["fruit"] = _tone([
		{"f0": 700.0, "f1": 1300.0, "d": 0.10},
		{"f0": 1300.0, "f1": 700.0, "d": 0.10},
		{"f0": 700.0, "f1": 1500.0, "d": 0.14}], 0.28)
	streams["death"] = _tone([
		{"f0": 640.0, "f1": 300.0, "d": 0.45},
		{"f0": 420.0, "f1": 160.0, "d": 0.45},
		{"f0": 240.0, "f1": 60.0, "d": 0.55}], 0.32)
	streams["ready"] = _tone([
		{"f0": 392.0, "f1": 392.0, "d": 0.13},
		{"f0": 523.0, "f1": 523.0, "d": 0.13},
		{"f0": 659.0, "f1": 659.0, "d": 0.13},
		{"f0": 784.0, "f1": 784.0, "d": 0.20}], 0.26)
	streams["extra"] = _tone([
		{"f0": 880.0, "f1": 880.0, "d": 0.07},
		{"f0": 0.0, "f1": 0.0, "d": 0.03},
		{"f0": 1174.0, "f1": 1174.0, "d": 0.07},
		{"f0": 0.0, "f1": 0.0, "d": 0.03},
		{"f0": 1568.0, "f1": 1568.0, "d": 0.12}], 0.26)
	streams["siren"] = _tone([
		{"f0": 240.0, "f1": 380.0, "d": 0.22},
		{"f0": 380.0, "f1": 240.0, "d": 0.22}], 0.16, true)
	streams["fright"] = _tone([
		{"f0": 150.0, "f1": 300.0, "d": 0.13},
		{"f0": 300.0, "f1": 150.0, "d": 0.13}], 0.16, true)
	streams["retreat"] = _tone([
		{"f0": 700.0, "f1": 1000.0, "d": 0.08},
		{"f0": 1000.0, "f1": 700.0, "d": 0.08}], 0.14, true)

	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		pool.append(p)
	loop_player = AudioStreamPlayer.new()
	loop_player.volume_db = LOOP_DB
	add_child(loop_player)

func _tone(segments: Array, vol: float, looping: bool = false) -> AudioStreamWAV:
	var total := 0
	for s in segments:
		total += int(float(s["d"]) * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var idx := 0
	var phase := 0.0
	for s in segments:
		var n := int(float(s["d"]) * RATE)
		var f0 := float(s["f0"])
		var f1 := float(s["f1"])
		for i in n:
			var t := float(i) / float(maxi(n, 1))
			var f: float = f0 + (f1 - f0) * t
			var v := 0.0
			if f > 1.0:
				phase = fmod(phase + f / float(RATE), 1.0)
				v = 1.0 if phase < 0.5 else -1.0
			var env := 1.0
			if not looping:
				var fade := 0.012
				if t < fade:
					env = t / fade
				elif t > 1.0 - fade:
					env = (1.0 - t) / fade
			data.encode_s16(idx * 2, int(clampf(v * vol * env, -1.0, 1.0) * 32000.0))
			idx += 1
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = data
	if looping:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = total
	return st

func play(key: String) -> void:
	if not enabled or not streams.has(key):
		return
	var p := pool[pool_index]
	pool_index = (pool_index + 1) % pool.size()
	p.stream = streams[key]
	p.play()

func play_loop(key: String) -> void:
	if current_loop == key:
		return
	current_loop = key
	if key == "" or not enabled:
		loop_player.stop()
		return
	loop_player.stream = streams[key]
	loop_player.play()

func stop_loop() -> void:
	play_loop("")
