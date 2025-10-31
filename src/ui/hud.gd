extends CanvasLayer

@onready var score_label: Label = $Score/ScoreLabel
@onready var powerup_label: Label = $Score/ScoreLabel/PowerupLabel
@onready var main_menu: Control = $MainMenu
@onready var end_menu: Control = $EndMenu
@onready var pause_menu: Control = $PauseMenu

signal start_game

func _ready() -> void:
	# Conectar las señales del MainMenu y EndMenu
	main_menu.start_game.connect(_on_main_menu_start_game)
	end_menu.restart_game.connect(_on_end_menu_restart_game)
	end_menu.return_to_main_menu.connect(_on_menu_return_to_main_menu)
	pause_menu.return_to_main_menu.connect(_on_menu_return_to_main_menu)

func update_score(score):
	score_label.text = "Score: %d" % [score]

func show_powerup(text: String):
	powerup_label.text = text
	powerup_label.show()
	powerup_label.modulate = Color.YELLOW

func hide_powerup():
	powerup_label.hide()

func _on_main_menu_start_game() -> void:
	start_game.emit()

func _on_main_open_loser_hud() -> void:
	end_menu.show_end_menu()

func _on_end_menu_restart_game() -> void:
	start_game.emit()

func _on_menu_return_to_main_menu() -> void:
	main_menu.show_main_menu()
	get_parent().return_to_main_menu()
