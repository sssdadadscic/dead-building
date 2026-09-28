extends Node
## 音效与氛围音乐

var _sfx := {}
var _music: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer

func _ready() -> void:
	for name in ["paper", "chime", "static", "door", "footstep"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/sfx/%s.wav" % name)
		p.volume_db = -6.0
		add_child(p)
		_sfx[name] = p
	_music = AudioStreamPlayer.new()
	_music.volume_db = -16.0
	add_child(_music)
	_heartbeat = AudioStreamPlayer.new()
	var hb: AudioStreamWAV = load("res://assets/sfx/heartbeat.wav")
	hb.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_heartbeat.stream = hb
	_heartbeat.volume_db = -14.0
	add_child(_heartbeat)

func play(name: String) -> void:
	if _sfx.has(name):
		_sfx[name].play()

func music_day() -> void:
	_switch_music("day_pad", -20.0)

func music_night() -> void:
	_switch_music("night_drone", -14.0)

func music_stop() -> void:
	_music.stop()

func _switch_music(name: String, vol: float) -> void:
	var stream: AudioStreamWAV = load("res://assets/sfx/%s.wav" % name)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	if _music.stream == stream and _music.playing: return
	_music.stream = stream
	_music.volume_db = vol
	_music.play()

func heartbeat(on: bool) -> void:
	if on and not _heartbeat.playing:
		_heartbeat.play()
	elif not on and _heartbeat.playing:
		_heartbeat.stop()
