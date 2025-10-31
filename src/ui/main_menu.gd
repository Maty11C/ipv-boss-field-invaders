extends Control

const AudioUtils = preload("res://src/utils/audio.gd")

@onready var music: AudioStreamPlayer = $Music

signal start_game

func _ready() -> void:
	music.bus = "Music"
	music.play()

func _on_start_button_pressed() -> void:
	hide()
	AudioUtils.fade_bus_volume(self, "Music", -80.0, 1.5, music.stop)
	start_game.emit()

func show_main_menu() -> void:
	show()
	# Reanudar música del menú principal
	if not music.playing:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0.0)
		music.play()
