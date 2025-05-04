extends CharacterBody2D

@export var _speed: int = 75
var pick_uper
@onready var disappear_timer = %Disappear_Timer

func _process(_delta):
	if(pick_uper == null):
		return
	var direction = global_position.direction_to(pick_uper.global_position)
	velocity = direction * _speed
	move_and_slide()

func assign_picker(picker: CharacterBody2D):
	pick_uper = picker
	disappear_timer.start()

func _on_disappear_timer_timeout():
	queue_free()
	if(pick_uper != null and pick_uper.has_method("add_pickup")):
		pick_uper.add_pickup()
