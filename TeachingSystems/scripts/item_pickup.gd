extends CharacterBody2D
## This script is responsible for the behaviour of the items dropped by enemies. After death
## the enemy spawns this entity at the same position as a child to the game. When the user
## gets near enough to the item then the item starts following the player and then
## disappears some time later while adding to the pick up counter of the game.

## This variable determines how fast the item follows the player after being picked up
@export var _speed: int = 75
## This variable holds the entity that picked up the item. Mostly the player.
var pick_uper
## This variable references the disappearance timer which starts after being picked up.
@onready var disappear_timer = %Disappear_Timer

func _process(_delta):
	if(pick_uper == null):
		return
	var direction = global_position.direction_to(pick_uper.global_position)
	velocity = direction * _speed
	move_and_slide()

## This function should be used by the entity picking up this item. It fills the pick uper
## variable so that we start following the entity and then the disappear timer starts.
func assign_picker(picker: CharacterBody2D):
	pick_uper = picker
	disappear_timer.start()

## This function should connecr to the disappear timer. After ending the timer notifies the item
## to delete itself and if the entity picking up the item has the method to add the pickup we
## call it to add 1 to the counter of pickups.
func _on_disappear_timer_timeout():
	queue_free()
	if(pick_uper != null and pick_uper.has_method("add_pickup")):
		pick_uper.add_pickup()
