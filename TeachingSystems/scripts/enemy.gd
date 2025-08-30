extends CharacterBody2D
## This script is attached to all drone enemies in the game. Its main function is to check when
## it should take damage, set the direction towards the user, move back when it receives knockback
## and leave drops in its dying position for the user to pick up

## This constant holds the drop the enemy leaves behind after death
const ITEM_PICKUP = preload("res://scenes/item_pickup.tscn")

## This variable should contain the game that has the enemy. Usually set when the game spawns
## the enemy so that we know where to leave the drops after death
@onready var game
## This variable contains a reference to the player in order for us to know who to follow
@onready var player = $"../Player"
## This variable points to the animator component.
@onready var drone_player = $Drone_Player
## This variable points to the audio clip for when the enemy takes damage
@onready var take_damage_audio = $TakeDamageAudio
## This variable points to the audio clip for when the enemy dies
@onready var die_audio = $DieAudio

## This variable informs how fast the enemy can move
@export var _speed: int = 50
## This variable holds how much damage the enemy can take
@export var _health: int = 4
## This variable informs the enemy if it should get knocked back. True by default
## but if it changes to false the enemy can't be pushed back
@export var receives_knockback: bool = true

func _physics_process(_delta):
	if(_health > 0 and player != null):
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * _speed
		move_and_slide()

## This function helps other components deal damage to the enemy. Usually after collision, the user
## should call this function with the amount of damage. After it's called the enemy's health gets
## lowered by the ammount, the animator plays the "Hit" animation and plays the take damage audio
## but then if its health is 0 or less it dies. After it dies it informs the game that the enemy
## counter should drop by one, and it leaves the drop it holds as a child to the game
## in the same position it died on
func take_damage(amount: int):
	_health -= amount
	drone_player.play("Hit")
	if(_health <= 0):
		die_audio.play()
		if(game == null):
			game = get_parent()
		if(game.has_method("decrease_enemy_number_by_one")):
			game.decrease_enemy_number_by_one()
		drone_player.play("Death")
		var drop_down = ITEM_PICKUP.instantiate()
		game.call_deferred("add_child",drop_down)
		drop_down.global_position = global_position
	else:
		take_damage_audio.play()
		drone_player.queue("Float")

## This function should be called when the enemy should be pushed back. Its usually when it takes
## damage and reauires a knockback strength as input. Depending on the strength it moves a set
## amount away from the player's position, unless it can't receive knockback
func receive_knockback(knockback_strength: float):
	if(receives_knockback):
		var knockback_direction = player.global_position.direction_to(global_position)
		var knockback = knockback_direction * knockback_strength
		global_position += knockback

## This function should be called but the enemy's parent. It holds the game, which is it's parent
## and with that the enemy can inform the game of when it should decrease the enemy counter number
## and know where to elave it's drop
func set_game(parnt: Node2D):
	game = parnt
