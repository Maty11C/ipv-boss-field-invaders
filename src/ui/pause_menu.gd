extends Control

signal return_to_main_menu

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause_menu"):
		visible = !visible
		get_tree().paused = visible	

func _on_resume_button_pressed() -> void:
	hide()
	get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	hide()
	return_to_main_menu.emit()
