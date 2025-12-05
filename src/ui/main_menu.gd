extends Control

const Audio = preload("res://src/utils/audio.gd")

@onready var music: AudioStreamPlayer = $Music

signal start_game
signal controls_requested
signal options_requested

func _ready() -> void:
	music.bus = "Music"
	music.play()

func _on_start_button_pressed() -> void:
	hide()
	Audio.fade_bus_volume(self, "Music", -80.0, 1.5, music.stop)
	start_game.emit()

func show_main_menu() -> void:
	show()
	# Reanudar música del menú principal
	if not music.playing:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0.0)
		music.play()

func _on_controls_button_pressed() -> void:
	controls_requested.emit()

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_options_button_pressed() -> void:
	options_requested.emit()
