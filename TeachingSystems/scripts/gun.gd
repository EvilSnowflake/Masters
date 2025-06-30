extends Area2D

@onready var shooting_point = %Shooting_Point
@onready var shooting_timer = %Shooting_Timer
@onready var shoot_effect = %Shoot_Effect
@onready var white_red_gun = %White_Red_Gun
@onready var gun_range = %Gun_Range

var bullet_persistance : int
var bullet_damage: int

@export var default_bullet_persistance: int = 0
@export var default_bullet_damage: int = 1
@export var default_range: int = 150
@export var default_attack_speed : float = 0.5 

func _physics_process(_delta):
	#Test comment
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

func set_default_values():
	print("reset gun values")
	set_bullet_persistance(default_bullet_persistance)
	set_bullet_damage(default_bullet_damage)
	set_range(default_range)
	set_attack_speed(default_attack_speed)

func shoot():
	const BULLET = preload("res://scenes/bullet.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = shooting_point.global_position
	new_bullet.global_rotation = shooting_point.global_rotation
	if(new_bullet.has_method("set_damage")):
		new_bullet.set_damage(bullet_damage)
	if(new_bullet.has_method("set_persistance")):
		new_bullet.set_persistance(bullet_persistance)
	shooting_point.add_child(new_bullet)

func _on_timer_timeout():
	shoot_effect.play("Fire")
	shoot()

func set_range(value: int):
	gun_range.shape.radius = value

func get_range() -> int:
	return gun_range.shape.radius

func set_bullet_damage(value: int):
	bullet_damage = value

func get_bullet_damage() -> int:
	return bullet_damage
	
func set_bullet_persistance(value: int):
	bullet_persistance = value

func get_bullet_persistance() -> int:
	return bullet_persistance

func set_attack_speed(value: float):
	shooting_timer.wait_time = value
	
func get_attack_speed() -> float:
	return shooting_timer.wait_time
