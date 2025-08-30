extends Area2D
## This script should be attached to any bullet fired, it is an area that checks if it collides
## with any enemy or foreground object, it only checks for the first and second collision mask.
## It contains values for the logic of the bullet, like speed and damage, which can be changed
## with the appropriate functions

## Constant value that determines how much distance the bullet can reach
## used together with travelled distance
const _bullet_range: int = 1200

## Variable that determines the speed the bullet travels in
var _bullet_speed: int = 1000
## Variable the keeps track of the distance the bullet has travelled
## Used together with vullet range
var _travelled_distance: int = 0
## Variable that determines how much life the enemy takes when collided with
var _bullet_damage: int = 1
## Variable determining the distance the enemy should be pushed when damaged
var _bullet_knockback: float = 10
## Variable that determines how many times the bullet can penetrate enemies and walls
var _bullet_persistance = 0

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * _bullet_speed * delta
	_travelled_distance += _bullet_speed * delta
	
	if(_travelled_distance > _bullet_range):
		queue_free()

## This function is called when the bullet enters a collider
## Here I remove 1 bullet persistance and if the object collided with has the
## ability to take damage and receive knockback then I call thos functions
func _on_body_entered(body):
	if(_bullet_persistance == 0):
		queue_free()
	else:
		_bullet_persistance -= 1
	if(body.has_method("take_damage")):
		body.take_damage(_bullet_damage)
	if(body.has_method("receive_knockback")):
		body.receive_knockback(_bullet_knockback)

## This function can be used by other scripts to change the _buttlet_damage variable
func set_damage(value: int):
	_bullet_damage = value

## This function can be used by other scripts to change the _bullet_persistance variable
func set_persistance(value: int):
	_bullet_persistance = value
