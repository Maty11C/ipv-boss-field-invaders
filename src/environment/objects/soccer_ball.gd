extends RigidBody2D

signal picked_up

func _ready():
	freeze = false
	set_contact_monitor(true)
	max_contacts_reported = 1

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("picked_up")
		queue_free()
