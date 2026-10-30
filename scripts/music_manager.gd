extends Node
const MENU_TRACK: AudioStream = preload("res://music/Adventure Theme.mp3")
const GAME_TRACK: AudioStream = preload("res://music/MainMenu.mp3")
var _player: AudioStreamPlayer
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 _player = AudioStreamPlayer.new()
 _player.name = "BackgroundMusic"
 _player.bus = &"Music"
 _player.process_mode = Node.PROCESS_MODE_ALWAYS
 add_child(_player)
 play_menu_music()
func play_menu_music() -> void:
 _play_track(MENU_TRACK)
func play_game_music() -> void:
 _play_track(GAME_TRACK)
func _play_track(track: AudioStream) -> void:
 if _player.stream == track and _player.playing: return
 _player.stream = track
 _player.play()
