extends Control

signal restart_game
signal return_to_main_menu

func show_end_menu() -> void:
	show()

func hide_end_menu() -> void:
	hide()

func _on_restart_button_pressed() -> void:
	hide_end_menu()
	restart_game.emit()

func _on_main_menu_button_pressed() -> void:
	hide_end_menu()
	return_to_main_menu.emit()
