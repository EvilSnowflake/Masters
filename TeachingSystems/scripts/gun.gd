extends Area2D
## This script is used by the gun entity the player holds. There is no way to control this
## object and it independantly shoots enemy objects applying damage to them and pushing them.
## While playing the gun checks around it at a specific range to find the closest enemy
## turns towards it and shoots. If there is no enemy close it has a default position that rotates to

## This variable references the point on where the bullet begins when fired
@onready var shooting_point = %Shooting_Point
## This variable references the timer that determines when the gun can fire again
@onready var shooting_timer = %Shooting_Timer
## This variable references an animated sprite that playes when the gun fires
@onready var shoot_effect = %Shoot_Effect
## This variable references the sprite of the gun
@onready var white_red_gun = %White_Red_Gun
## This variable references the collision shape that checks which enemies exist close to the
## gun.
@onready var gun_range = %Gun_Range

## This variable determines how many entities the bullet fired can pass through
var bullet_persistance : int
## This variable determines how much health the enemy loses on collision
var bullet_damage: int

## This variable determines the default value of bullet persistance so that when we enter
## the game scene the value returns to default
@export var default_bullet_persistance: int = 0
## This variable determines the default value of bullet damage so that when we enter
## the game scene the value returns to default
@export var default_bullet_damage: int = 1
## This variable determines the default value of the gun's range so that when we enter
## the game scene the value returns to default
@export var default_range: int = 150
## This variable determines the default value the shooting timer so that when we enter
## the game scene the value returns to default
@export var default_attack_speed : float = 0.5 

## This signal is emitted when the gun fires
signal on_shoot_performed()

func _physics_process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() == 0:
		shooting_timer.stop()
		global_rotation_degrees = 0
		white_red_gun.flip_v = false
		return
	if(shooting_timer.is_stopped()):
		shooting_timer.start()
	var target_enemy = enemies_in_range[0]
	look_at(target_enemy.global_position)
	if(global_rotation_degrees < -90 or global_rotation_degrees > 90):
		white_red_gun.flip_v = true
	else:
		white_red_gun.flip_v = false

## This function should be called when the game begind, it returns all the gun's values
## to their default in order for them to not keep any changes from previous sessions
func set_default_values():
	#print_debug("reset gun values")
	set_bullet_persistance(default_bullet_persistance)
	set_bullet_damage(default_bullet_damage)
	set_range(default_range)
	set_attack_speed(default_attack_speed)

## This function should be called when we want to fire a bullet. Firstly it emits a signal
## for other scenes, then using a preloaded bullet scene it instantiates a bullet and then
## sets its position to the shooting point after which it sets it's damage and persistance
## to the appropriate values and in the end it sets the shooting point as the parent of the
## bullet.
func shoot():
	on_shoot_performed.emit()
	const BULLET = preload("res://scenes/bullet.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = shooting_point.global_rotation
	if(new_bullet.has_method("set_damage")):
		new_bullet.set_damage(bullet_damage)
	if(new_bullet.has_method("set_persistance")):
		new_bullet.set_persistance(bullet_persistance)
	shooting_point.add_child(new_bullet)

## This function should be connected to the shooting timer. WHen the timer ends it plays
## the shooting animated sprite and then fires.
func _on_timer_timeout():
	shoot_effect.play("Fire")
	shoot()

## This function should be used by other scenes to set the value of the gun's collision shape radius
func set_range(value: int):
	gun_range.shape.radius = value

## This function returns the gun's collision shape radius
func get_range() -> int:
	return gun_range.shape.radius

## This function should be used by other scenes to set the value of the bullet's damage
func set_bullet_damage(value: int):
	bullet_damage = value

## This function returns the bullet's current damage value
func get_bullet_damage() -> int:
	return bullet_damage

## This function should be used by other scenes to set the value of the bullet's persistance
func set_bullet_persistance(value: int):
	bullet_persistance = value

## This function returns the current value of the bullet's persistance
func get_bullet_persistance() -> int:
	return bullet_persistance

## This function should be used by other scenes to change the wait time of the shooting timer
## so that the gun fires more frequently
func set_attack_speed(value: float):
	if shooting_timer.wait_time <= 0.05:
		print_debug("Wait time can't be reduced further")
		return
	shooting_timer.wait_time = value

## This function returns the shooting timer's current wait time
func get_attack_speed() -> float:
	return shooting_timer.wait_time
