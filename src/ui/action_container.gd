extends MarginContainer

@export var action: String
@export var keys: String

@onready var action_label: Label = $HBoxContainer/ActionLabel
@onready var keys_label: Label = $HBoxContainer/KeysContainer/KeysLabel

func _ready() -> void:
	action_label.text = action
	keys_label.text = keys
