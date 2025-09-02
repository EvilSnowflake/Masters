extends CharacterBody2D
## This script should be attached to the character the user controls during the stages.
## It gives the character a way to move inside the stage, keeps track of the user's level,
## recources to next level, health, and other stats of the user and their gun. It is also
## in charge of increasing the user's stats after a level up, a correct answer or decrease
## the stats with a wrong answer. There is also functions for the user to take damage and
## for animations.

const INCREASED: String = "INCREASED_TEXT"
const DECREASED: String = "DECREASED_TEXT"
const HEALTH: String = "HEALTH_TEXT"
const MOVE_SPEED: String = "MOVE_SPEED_TEXT"
const RANGE: String = "RANGE_TEXT"
const PERSISTANCE: String = "PERSISTANCE_TEXT"
const DAMAGE: String = "DAMAGE_TEXT"
const NONE: String = "NONE_TEXT"
const FIRE_SPEED: String = "FIRE_SPEED_TEXT"

## This variable contains the total amount of recourses needed for the next level
var _lvl_req = 3
## This variable is used to check if the user has died
var _died: bool = false
## This variable is used to determine if the game is paused
var _paused_game: bool = false
## This variable contains the amount health the user currently has.
var _health: float
## This variable contains the maximum amount of health the user can currently acquire
var _max_health: float
## This variable shows how much damage the user should take at the next instance of damage
## it can be increased the more enemies are around the user
var _damage_rate: float
## This variable contains the user's current level
var _char_level: int
## This variable contains the amount of items need for the user to level up. It gets decreased
## each time the users picks up an item and if it goes to 0 then the user levels up
var _resources_to_lvl: int
## This variable should be filled with the instance of the current game
var game
## I don't currently know what this variable does ???
var stats_num: int = 5

## This variable contians the original amount of health the user should have at the start
## of the game. It replaces any health the user has during entering the game
## so that any change from a previous session doesn't stay.
@export var default_health : float = 20.0
## This variable contians the original amount of max_health the user should have at the start
## of the game. It replaces any max_health the user has during entering the game
## so that any change from a previous session doesn't stay.
@export var default_max_health: float = 20.0
## This variable contians the original amount of damage_rate the user should take
## of the game. It replaces any damage_rate the user takes during entering the game
## so that any change from a previous session doesn't stay.
@export var default_damage_rate: float = 5.0
## This variable contians the original level the user should have at the start
## of the game. It replaces any level the user has during entering the game
## so that any change from a previous session doesn't stay.
@export var default_char_level: int = 1
## This variable contians the original resources to next level the user should need at the start
## of the game. It replaces any resources to next level the user needs during entering the game
## so that any change from a previous session doesn't stay.
@export var default_resources_to_lvl: int = 0
## This variable contians the original amount of speed the user should have at the start
## of the game. It replaces the speed the user has during entering the game
## so that any change from a previous session doesn't stay.
@export var default_speed: int = 200
## This variable contains the speed that the user moves in the game. It has a set
## and get function inherently.
@export var _speed: int :
	set(value):
		_speed = value
	get:
		return _speed

## This variable contains a reference to the gun instance in the hierarchy
@onready var gun = %Gun
## This variable contains a reference to the character animator instance in the hierarchy
@onready var cyborg_player = %Cyborg_Player
## This variable contains a reference to the player sprite instance in the hierarchy
@onready var player_sprite = %Player_Sprite
## This variable contains a reference to the damage collision instance in the hierarchy
@onready var hurt_box = %Hurt_Box
## This variable contains a reference to the health bar instance in the hierarchy
@onready var health_bar = %Health_Bar

## This signal is emitted when the player's health goes to 0
signal health_depleted
## This signal is emitted when the player's level increases
signal on_levelup(change: String, clr: Color, lvl: int)
## This signal is emitted when the player takes a step
signal on_step_made()
## This signal is emitted when the player's gun fires
signal on_shoot_performed()
## This signal is emitted when the player picks up an item
signal on_item_picked()
## This signal is emitted when the player gets a reward
signal on_rewarded(powered: bool)
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)
## This signal should be emitted if the scene contains children that want to use the tts component
## By emitting it with the child scene their signals are connected to the tts.
signal send_scene_for_signals(scene)

## This enum is used to identify the type of reward the user should receive. It is between a
## Negative -1, and a Large 2.
enum Reward {NEGATIVE = -1, SMALL = 0, MEDIUM = 1, LARGE = 2}

func _ready():
	reset_values()
	_health = _max_health
	game = get_parent()
	_resources_to_lvl = _lvl_req
	if gun.has_signal("on_shoot_performed"):
		gun.on_shoot_performed.connect(emit_shoot_signal)

# The way the character moves is that we get the user's input amd depending the direction
# they currently press we move the character at a set speed and flip the character sprite
# that way and depending on the character velocity we play the proper animation and 
# check if the user would get hit.
func _physics_process(delta):
	if _paused_game == true or _died == true:
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

## This function should be called every frame. It checks every enemy in a specific
## collision area. After finding that number using the damage rate it then calculates how much 
## damage the user should receive this frame. But then using the delta input we translate
## the damage each frame to a damage each second. Then if the health we have becomes 0 or less
## we play the death animation and inform of the user's death.
func get_hit(delta):
	if(_died):
		return
	var overlapping_mobs = hurt_box.get_overlapping_bodies()
	if overlapping_mobs.size() <=0 :
		return
	send_only_announcement.emit("Got Hit")
	_health -= _damage_rate * overlapping_mobs.size() * delta
	health_bar.value = (100 * _health)/_max_health
	if(_health <= 0.0 ):
		cyborg_player.play("Death")
		health_depleted.emit()
		_died = true

## This function should be called when we want the character to play their idle animation
func play_idle_animation() -> void:
	cyborg_player.play("Idle")

## This function should be called when we want the character to play their run animation
func play_run_animation() -> void:
	cyborg_player.play("Run")

## This function should be called by the recourses left by the enemies. After being called
## it reduces the amount of items required for level up, and then if it goes to 0
## it adds a level to the user, updates the amount of pickups on the game and emits
## a signal to play the appropriate sound effect.
func add_pickup():
	_resources_to_lvl -= 1
	if(_resources_to_lvl == 0):
		print_debug("Level Up")
		level_up()
	if(game.has_method("update_pickups")):
		on_item_picked.emit()
		game.update_pickups(_char_level, _lvl_req - _resources_to_lvl , _lvl_req)

## This function should be used when we want to level the user up. At first it increases
## the character level variable, increases the amount of recourses the user then needs
## to level up and after that it gives the user an appropriate reward for their level. In a
## regular level up the reward is small, if the level can be divided by 5 then the reward is
## a medium one, and then if it can be divided by 10 then the reward is large. After
## calculating the size of the reward it emits a signal with the stat change, the color green
## and the level of the character.
func level_up():
	_char_level += 1
	_lvl_req = int(_lvl_req * 1.5)
	_resources_to_lvl = _lvl_req
	var stat_change: Array[String] = []
	if(_char_level%10 == 0):
		stat_change = give_reward(Reward.LARGE)
	elif(_char_level%5 == 0):
		stat_change = give_reward(Reward.MEDIUM)
	else:
		stat_change = give_reward(Reward.SMALL)
	for change in stat_change:
		on_levelup.emit(change + tr(INCREASED), Color.GREEN, _char_level)

## This function should be called when an item comes in contact with the user's pickup
## collision area. It assigns the items picker as the user
func _on_pickup_box_body_entered(body):
	if(body.has_method("assign_picker")):
		body.assign_picker(self)

## This function should be called to increase the user's maximum amount of
## health while also healing the user
func add_max_health(value: int):
	_max_health += value
	_health = _max_health

## This function should be called to increase the user's speed value
func add_speed(value: int):
	_speed += value

## This function should be called to change the gun's collision size
func add_range(value: int):
	gun.set_range(value + gun.get_range())

## This function should be called to increase the damage of the gun's bullets
func add_bullet_damage(value: int):
	gun.set_bullet_damage(gun.get_bullet_damage() + value)

## This function should be called to increase the amount of times the gun's bullets can
## pass though enemies and walls.
func add_bullet_persistance(value: int):
	gun.set_bullet_persistance(gun.get_bullet_persistance() + value)

## This function should be called to increase the time that it takes for the user's gun
## to shoot.
func add_gun_attack_speed(value: float):
	gun.set_attack_speed(gun.get_attack_speed() - gun.get_attack_speed()*value)

## This function should be called when the user answers wrong on a stage question. It sets the
## user's stats at a minimum so that it's really hard for them to continue after that. 
func disempower():
	_max_health = _max_health*(0.1)
	_health = _max_health
	_speed = int(_speed*(0.5))
	gun.set_range(gun.get_range()*(0.5))
	gun.set_bullet_persistance(0)
	gun.set_bullet_damage(1)

## This function should be called when we want to either reward the user positively or
## negatively. Depending on the input reward type the function increases some stats on random
## or decreases all stats. Some stats are only increased on large rewards but having a negative
## reward decreases all stats that can be decreased.
func give_reward(rwrd: Reward) -> Array[String]:
	var rand_stat = randi_range(1,2)
	match rwrd:
		Reward.NEGATIVE:
			on_rewarded.emit(false)
			disempower()
			return([tr(HEALTH),tr(MOVE_SPEED),tr(RANGE),tr(PERSISTANCE),tr(DAMAGE)])
		Reward.SMALL:
			on_rewarded.emit(true)
			_max_health += 1
			_health += 1
			if(rand_stat == 1):
				add_speed(10)
				return([tr(MOVE_SPEED),tr(HEALTH)])
			else:
				add_range(5)
				return([tr(RANGE),tr(HEALTH)])
		Reward.MEDIUM:
			on_rewarded.emit(true)
			_max_health += 5
			_health += 5
			add_gun_attack_speed(0.1)
			return([tr(FIRE_SPEED),tr(HEALTH)])
		Reward.LARGE:
			on_rewarded.emit(true)
			_max_health += 10
			_health = _max_health
			if(rand_stat == 1):
				add_bullet_damage(1)
				return([tr(DAMAGE),tr(HEALTH)])
			else:
				add_bullet_persistance(1)
				return([tr(PERSISTANCE),tr(HEALTH)])
	return([tr(NONE)])

## This function should be called when we want to change the user's and their gun's stats to their
## defaut values.
func reset_values()-> void:
	_health = default_health
	_max_health = default_max_health
	_damage_rate = default_damage_rate
	_char_level = default_char_level
	_resources_to_lvl = default_resources_to_lvl
	_speed = default_speed
	if "set_default_values" in gun:
		gun.set_default_values()

## This function should be used by the game instance to infrom the user that the game is paused
## so that they can't input actions
func set_paused_status(value: bool) -> void:
	_paused_game = value

## This function emits a signal for when the user takes a step. It plays an audio clip accordingly.
func emit_step_signal() -> void:
	on_step_made.emit()

## This function emits a signal for then the user's gun fires. It plays the necessary audio clip.
func emit_shoot_signal() -> void:
	on_shoot_performed.emit()
