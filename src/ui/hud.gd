extends CanvasLayer

const AudioUtils = preload("res://src/utils/audio.gd")

@onready var music: AudioStreamPlayer = $MainMenu/Music
@onready var main_menu: Control = $MainMenu
@onready var end_menu: Control = $EndMenu

@onready var main_menu_button: Button = $EndMenu/ButtonsContainer/VBoxContainer/MainMenuButton

@onready var score_label: Label = $Score/ScoreLabel
@onready var powerup_label: Label = $Score/ScoreLabel/PowerupLabel

signal start_game

func _ready() -> void:
	music.bus = "Music"
	music.play()

func update_score(score):
	score_label.text = "Score: %d" % [score]

func show_powerup(text: String):
	powerup_label.text = text
	powerup_label.show()
	powerup_label.modulate = Color.YELLOW

func hide_powerup():
	powerup_label.hide()

func _on_start_button_pressed() -> void:
	main_menu.visible = false
	AudioUtils.fade_bus_volume(self, "Music", -80.0, 1.5, music.stop)
	start_game.emit()

func _on_main_open_loser_hud() -> void:
	end_menu.visible = true

func _on_restart_button_pressed() -> void:
	end_menu.visible = false
	start_game.emit()

func _on_main_menu_button_pressed() -> void:
	end_menu.visible = false
	main_menu.visible = true
	
	# Detener el abucheo si está sonando
	get_parent().stop_boo_sound()
	
	# Volver al menú inicial - reanudar "Muchachos"
	if not music.playing:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0.0)
		music.play()
