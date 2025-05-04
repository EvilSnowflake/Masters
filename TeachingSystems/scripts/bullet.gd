extends Area2D

var _bullet_speed: int = 1000
var _travelled_distance: int = 0
var _bullet_damage: int = 1
var _bullet_knockback: float = 10
var _bullet_persistance = 0
const _bullet_range: int = 1200

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * _bullet_speed * delta
	_travelled_distance += _bullet_speed * delta
	
	if(_travelled_distance > _bullet_range):
		queue_free()

func _on_body_entered(body):
	if(_bullet_persistance == 0):
		queue_free()
	else:
		_bullet_persistance -= 1
	if(body.has_method("take_damage")):
		body.take_damage(_bullet_damage)
	if(body.has_method("receive_knockback")):
		body.receive_knockback(_bullet_knockback)

func set_damage(value: int):
	_bullet_damage = value

func set_persistance(value: int):
	_bullet_persistance = value
