extends CharacterBody2D

@export var _speed: int :
	set(value):
		_speed = value
	get:
		return _speed
		
var _lvl_req = 3
var _died: bool = false
var _paused_game: bool = false

var _health: float
var _max_health: float
var _damage_rate: float
var _char_level: int
var _resources_to_lvl: int

@export var default_health : float = 20.0
@export var default_max_health: float = 20.0
@export var default_damage_rate: float = 5.0
@export var default_char_level: int = 1
@export var default_resources_to_lvl: int = 0
@export var default_speed: int = 200

@onready var gun = %Gun
@onready var cyborg_player = %Cyborg_Player
@onready var player_sprite = %Player_Sprite
@onready var hurt_box = %Hurt_Box
@onready var health_bar = %Health_Bar

signal health_depleted
signal on_levelup(change: String, clr: Color, lvl: int)
signal on_step_made()
signal on_shoot_performed()
signal on_item_picked()
signal on_rewarded(powered: bool)

var game
enum Reward {NEGATIVE = -1, SMALL = 0, MEDIUM = 1, LARGE = 2}
var stats_num: int = 5

func _ready():
	print_debug("reset char")
	reset_values()
	
	_health = _max_health
	game = get_parent()
	_resources_to_lvl = _lvl_req
	
	if gun.has_signal("on_shoot_performed"):
		gun.on_shoot_performed.connect(emit_shoot_signal)

func _physics_process(delta):
	if _paused_game == true:
		return
	var direction = Input.get_vector("Left","Right","Up","Down")
	velocity = direction * _speed
	move_and_slide()
	if(direction[0] < 0):
		player_sprite.flip_h = true
	elif (direction[0] > 0):
		player_sprite.flip_h = false
	
	if(velocity.length() > 0.0 and !_died):
		play_run_animation()
	elif(velocity.length() <= 0.0 and !_died):
		play_idle_animation()
	get_hit(delta)
	

func get_hit(delta):
	if(_died):
		return
	var overlapping_mobs = hurt_box.get_overlapping_bodies()
	_health -= _damage_rate * overlapping_mobs.size() * delta
	health_bar.value = (100 * _health)/_max_health
	if(_health <= 0.0 ):
		cyborg_player.play("Death")
		health_depleted.emit()
		_died = true

func play_idle_animation() -> void:
	cyborg_player.play("Idle")
	
func play_run_animation() -> void:
	cyborg_player.play("Run")
	
func add_pickup():
	_resources_to_lvl -= 1
	if(_resources_to_lvl == 0):
		print_debug("Level Up")
		level_up()
	if(game.has_method("update_pickups")):
		on_item_picked.emit()
		game.update_pickups(_char_level, _lvl_req - _resources_to_lvl , _lvl_req)
	
func level_up():
	_char_level += 1
	_lvl_req = int(_lvl_req * 1.5)
	_resources_to_lvl = _lvl_req
	
	#print_debug(str(_char_level%5))
	#print_debug(str(_char_level%10))
	var stat_change: Array[String] = []
	if(_char_level%10 == 0):
		stat_change = give_reward(Reward.LARGE)
	elif(_char_level%5 == 0):
		stat_change = give_reward(Reward.MEDIUM)
	else:
		stat_change = give_reward(Reward.SMALL)
		
	for change in stat_change:
		on_levelup.emit(change + " INCREASED!", Color.GREEN, _char_level)

func _on_pickup_box_body_entered(body):
	if(body.has_method("assign_picker")):
		body.assign_picker(self)

func add_max_health(value: int):
	_max_health += value
	_health = _max_health
func add_speed(value: int):
	_speed += value
func add_range(value: int):
	gun.set_range(value + gun.get_range())
func add_bullet_damage(value: int):
	gun.set_bullet_damage(gun.get_bullet_damage() + value)
func add_bullet_persistance(value: int):
	gun.set_bullet_persistance(gun.get_bullet_persistance() + value)
func add_gun_attack_speed(value: float):
	gun.set_attack_speed(gun.get_attack_speed() + value)

func disempower():
	_max_health = _max_health*(0.1)
	_health = _max_health
	_speed = int(_speed*(0.5))
	gun.set_range(gun.get_range()*(0.5))
	gun.set_bullet_persistance(0)
	gun.set_bullet_damage(1)

func give_reward(rwrd: Reward) -> Array[String]:
	var rand_stat = randi_range(1,2)

	match rwrd:
		Reward.NEGATIVE:
			on_rewarded.emit(false)
			disempower()
			return(["HP","MOVE SPEED","RANGE","PERSISTANCE","DAMAGE"])
		Reward.SMALL:
			on_rewarded.emit(true)
			_max_health += 1
			_health += 1
			if(rand_stat == 1):
				add_speed(10)
				return(["MOVE SPEED","HEALTH"])
			else:
				add_range(5)
				return(["RANGE","HEALTH"])
		Reward.MEDIUM:
			on_rewarded.emit(true)
			_max_health += 5
			_health += 5
			add_gun_attack_speed(0.1)
			return(["FIRE SPEED","HEALTH"])
		Reward.LARGE:
			on_rewarded.emit(true)
			_max_health += 10
			_health = _max_health
			if(rand_stat == 1):
				add_bullet_damage(1)
				return(["DAMAGE","HEALTH"])
			else:
				add_bullet_persistance(1)
				return(["PERSISTANCE","HEALTH"])
	return(["NONE"])

func reset_values()-> void:
	_health = default_health
	_max_health = default_max_health
	_damage_rate = default_damage_rate
	_char_level = default_char_level
	_resources_to_lvl = default_resources_to_lvl
	_speed = default_speed
	if "set_default_values" in gun:
		gun.set_default_values()

func set_paused_status(value: bool) -> void:
	_paused_game = value

func emit_step_signal() -> void:
	on_step_made.emit()

func emit_shoot_signal() -> void:
	on_shoot_performed.emit()
