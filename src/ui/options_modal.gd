extends Control

signal modal_opened
signal modal_closed

var was_paused_before: bool = false
var pause_menu_was_visible: bool = false

@onready var master_slider: HSlider = $Background/Panel/VBoxContainer/OptionsContainer/SoundSection/MasterVolume/HSlider
@onready var music_slider: HSlider = $Background/Panel/VBoxContainer/OptionsContainer/SoundSection/MusicVolume/HSlider
@onready var ambience_slider: HSlider = $Background/Panel/VBoxContainer/OptionsContainer/SoundSection/AmbienceVolume/HSlider
@onready var sfx_slider: HSlider = $Background/Panel/VBoxContainer/OptionsContainer/SoundSection/SFXVolume/HSlider
@onready var comments_slider: HSlider = $Background/Panel/VBoxContainer/OptionsContainer/SoundSection/CommentsVolume/HSlider

func _ready() -> void:
	hide()
	_load_volume_settings()
	_connect_sliders()

func _connect_sliders() -> void:
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	ambience_slider.value_changed.connect(_on_ambience_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	comments_slider.value_changed.connect(_on_comments_volume_changed)

func _load_volume_settings() -> void:
	# Cargar valores actuales de los buses de audio
	master_slider.value = _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	music_slider.value = _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	ambience_slider.value = _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")))
	sfx_slider.value = _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	comments_slider.value = _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Comments")))

func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume("Master", value)

func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume("Music", value)

func _on_ambience_volume_changed(value: float) -> void:
	_set_bus_volume("Ambience", value)

func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume("SFX", value)
	
func _on_comments_volume_changed(value: float) -> void:
	_set_bus_volume("Comments", value)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	var db_value = _linear_to_db(linear_value)
	AudioServer.set_bus_volume_db(bus_idx, db_value)

func _linear_to_db(linear: float) -> float:
	# Convertir valor lineal (0-100) a decibelios
	if linear <= 0:
		return -80.0
	return linear_scale(linear, 0.0, 100.0, -30.0, 0.0)

func _db_to_linear(db: float) -> float:
	# Convertir decibelios a valor lineal (0-100)
	if db <= -80.0:
		return 0.0
	return linear_scale(db, -30.0, 0.0, 0.0, 100.0)

func linear_scale(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

func show_modal() -> void:
	# Guardar el estado de pausa anterior
	was_paused_before = get_tree().paused
	# Verificar si el pause menu está visible y guardarlo
	var hud_parent = get_parent()
	if hud_parent and hud_parent.has_node("PauseMenu"):
		pause_menu_was_visible = hud_parent.get_node("PauseMenu").visible
		if pause_menu_was_visible:
			hud_parent.get_node("PauseMenu").hide()
	# Pausar el juego solo si está activo
	if hud_parent and hud_parent.has_method("is_game_active") and hud_parent.is_game_active():
		get_tree().paused = true
	show()
	modal_opened.emit()

func hide_modal() -> void:
	hide()
	# Restaurar el estado de pausa anterior
	get_tree().paused = was_paused_before
	# Restaurar la visibilidad del pause menu si estaba visible
	var hud_parent = get_parent()
	if hud_parent and hud_parent.has_node("PauseMenu") and pause_menu_was_visible:
		hud_parent.get_node("PauseMenu").show()
	pause_menu_was_visible = false
	modal_closed.emit()

func _on_close_button_pressed() -> void:
	hide_modal()

# Permitir cerrar el modal con ESC
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_menu"):
		hide_modal()
		# Consumir el evento para evitar que active el pause_menu
		get_viewport().set_input_as_handled()

# Cerrar el modal cuando se hace clic fuera de él
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		hide_modal()

# Prevenir que se cierre cuando se hace clic dentro del panel
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Consume el evento para evitar que llegue al fondo
		get_viewport().set_input_as_handled()
