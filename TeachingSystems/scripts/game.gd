extends Node2D
## This script contains all the functionality of the gameplay part of the program. Here we spawn
## enemies for the player, we show their level ups, increases to statistics, we can pause the game
## or return to the main menu after the user quits or dies. Here we also keep track of the players
## wrong and right answers, how many enemies they beat, total time spent in the game and their level
## which we send to the main menu to save localy.

const CHANGED_STATS_LABEL = preload("res://scenes/changed_stats_label.tscn")
const TOTAL_ENEMIES_TEXT: String = "total_enemies"
const TOTAL_TIME_TEXT: String = "total_time"
const CORRECT_ANSWERS_TEXT: String = "correct_answers"
const WRONG_ANSWERS_TEXT: String = "wrong_answers"
const LEVEL_TEXT: String = "level"
const INCREASED: String = "INCREASED_TEXT"
const DECREASED: String = "DECREASED_TEXT"

## This variable references a path follow 2D object on the hierarchy. It is an item which follows
## a specific path on the scene into which we will spawn enemies.
@onready var path_follow_2d = %PathFollow2D
## This variables references a timer on the hierarchy which determines when we can spawn a new enemy
@onready var spawn_timer = %Spawn_Timer
## This variable references a label which informs the user which wave they are currently on
@onready var wave_announcer = %Wave_Announcer
## This variable references the player inside the scene
@onready var player = $Player
## This variable references a label which shows the amount of enemies left during a wave
@onready var enemies_anouncer = %Enemies_Announcer
## This variable references a label which shows the user's level
@onready var items_announcer = %Items_Announcer
## This variable references a progress bar which when filled gives a level to the player
@onready var level_bar = %Level_Bar
## This variable references the parent of all pauses objects. The children include: the pause menu,
## the stage question and the multiplication table for the stage
@onready var pauses = %Pauses
## This variable references the parent item of all statistics like enemies left and level
@onready var statistics_container = %Statistics_Container
## This variable references an object containing the audio clip which plays during the game
@onready var game_music = %Game_Music
## This variable references a timer which keeps track of the players time spent playing
@onready var time_timer = %Time_Timer
## This variable references a label into which we show the players time spent playing
@onready var game_timer = %Game_Timer

## This variable contains the number of the multiplication table we are currently on.
## This depends on which stage the user has entered from the menu. It informs the questions that
## we ask the user, how many enemies will spawn in a wave and the stage miltiplication table hint 
## at the start
@export var _propedia_num: int = 1
## This variable keeps track how many enemies are left to spawn during a wave
@export var _enemies_left: int = 0
## This variable keeps track of how many enemies are currently on the scene
@export var _enemies_left_alive: int = 0
## This variable counts the wave the user is currently on
@export var _wave: int = 0
## This variable should contain the button which opens the audio menu
@export var audio_button: Button
## This variable should contain the control objects that are on the pause menu
@export var pause_interactive_item_arrray: Array[Control]
## This variable should contain descriptions for all the control object on the pause menu
@export var pause_text_for_interactive_items: Array[String]

## This variable determines if the user is dead. It ca be changed by the user when their health
## depletes
var _user_died = false
## This variable determines how many waves the stage has
var _max_waves: int = 10
## This variable should be filled with a reference to the stage menu scene
var stage_menu
## This variable determines if the game is paused
var _paused: bool = false
## This variable contains a dictionary with the user statistics like total enemies killed
## or total time spent, and should be filled during gameplay and sent at the end to the main menu
var end_stats : Dictionary = {
	"total_enemies" = 0.0,
	"total_time" = 0.0,
	"correct_answers" = 0.0,
	"wrong_answers" = 0.0,
	"level" = 0.0
}

## This signal should be emitted when a button is pressed so that a sound is played
signal play_button_sound()
## This signal is emitted when the user takes a step so that a sound will be played
signal on_step_made()
## This signal is emitted when the gun gets fired so that a sound is played
signal on_shoot_performed()
## This signal is emitted when the player picks up an item so that a sound will be played
signal on_player_item_picked_up()
## This signal is emitted when the user levels up so that a sound is played
signal on_player_leveled_up()
## This signal is emitted when the user dies so that a sound will be played
signal on_user_die()
## This signal is emitted when the player gets powered up or down but answering questions or
## leveling up
signal on_player_rewarded(powered: bool)
## This signal is emitted when we want to show the audio menu
signal show_audio_frame()
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)
## This signal should be emitted if the scene contains children that want to use the tts component
## By emitting it with the child scene their signals are connected to the tts.
signal send_scene_for_signals(scene)

func _ready():
	time_timer.timeout.connect(_on_time_timer_timeout)
	player.on_levelup.connect(_player_lvlup)
	spawn_timer.start()
	if player.has_signal("on_shoot_performed"):
		player.on_shoot_performed.connect(_emit_shoot_signal)
	if player.has_signal("on_step_made"):
		player.on_step_made.connect(_emit_on_step_made)
	if player.has_signal("on_item_picked"):
		player.on_item_picked.connect(_emit_player_pickup_signal)
	if player.has_signal("on_rewarded"):
		player.on_rewarded.connect(_emit_player_rewarded)
	if pauses.get_child(1).has_signal("answer_given"):
		pauses.get_child(1).answer_given.connect(_on_stage_question_answer)
	if pauses.get_child(1).has_signal("too_many_wrong_answers"):
		pauses.get_child(1).too_many_wrong_answers.connect(_on_too_many_wrong_answers)
	if audio_button != null:
		audio_button.pressed.connect(_on_audio_button_pressed)

func _process(_delta):
	if(Input.is_action_just_pressed("Escape")):
		pause(0)
	if(_user_died):
		game_music.set_volume_db(game_music.volume_db - 20*_delta)

## This function is used to create enemies duirng the game. Using a preloaded scene of and enemy
## I pick a random spot on the path 2d which encircles the stage to spawn it, and after that I make 
## the enemy a child of the game scene and gives a reference of the game to the enemy for functions
## inside their script.
func spawn_enemy() -> void:
	var new_mob = preload("res://scenes/enemy.tscn").instantiate()
	path_follow_2d.progress_ratio = randf()
	new_mob.global_position = path_follow_2d.global_position
	add_child(new_mob)
	if(new_mob.has_method("set_game")):
		new_mob.set_game(self)

## This function uses a preloaded scene of a label to inform the user of any stat changes. If the
## user levels up or answers a stage question then this function is called with what stat changed
## and the color. The color depends on if the change is good or bad. After instantiating the label
## I set it's parent to the statistics container object and set it's color and text. The label then
## deletes itself after some time.
func spawn_stat_notification(message: String, color: Color) -> void:
	var new_notification: Label = CHANGED_STATS_LABEL.instantiate()
	statistics_container.add_child(new_notification)
	new_notification.set("theme_override_colors/font_color",color)
	new_notification.text = message

## This function should be connected to the spawn timer object in the hierarchy. When the timer
## ends we check if there are any enemies left to spawn and if there are we spawn 1 enemy and remove
## one from the total while also notifying the user. If there are no more left then I stop the timer
## and increase the wave count and when 2 seconds pass I re-enable it. If we have reached the max
## number of waves I return the user to the main menu since that means they won the stage.
func _on_spawn_timer_timeout() -> void:
	if(_enemies_left > 0):
		spawn_enemy()
		_enemies_left -= 1
		_enemies_left_alive += 1
		enemies_anouncer.text = str(_enemies_left_alive)
	if(_enemies_left_alive == 0):
		spawn_timer.stop()
		await get_tree().create_timer(2.0).timeout
		if(_wave < _max_waves):
			_increase_wave()
			spawn_timer.start()
			return
		return_to_stage_menu()

## This function should be called whenever I want to stop the gameplay. There are 3 types of pause
## and depending on the input I show the appropriate one by enabling 1 of the children in the pauses
## object. In 2 of the types I check if the game is already paused, if it isn't I stop the game 
## music set the time scale to 0 so that the scene stops and stop the player from moving. Otherwise
## I re enable the music and set the time scale to 1. Those 2 types include the starting
## multiplication table hint for the number we are currently in and the regular pause menu which has
## the buttons resume, audio and reutrn to main menu. In the first pause I also need to send the
## buttons to the tts component so that the user can interact with them, on the second one other
## than showing it I also notify it to start making the question for the user, and give it the
## stage number and the wave number to help it. Lastly for the third one I have to create the
## material since we have the 2 numbers and after making the material I input it to the label
## containing the text.
func pause(pause_kind: int) -> void:
	if(_paused):
		if(pause_kind == 0 or pause_kind == 2):
			game_music.stream_paused = false
		send_interactive_items.emit([],[])
		pauses.get_child(pause_kind).hide()
		time_timer.start()
		Engine.time_scale = 1
	else:
		if(pause_kind == 0 or pause_kind == 2):
			game_music.stream_paused = true
		pauses.get_child(pause_kind).show()
		time_timer.stop()
		Engine.time_scale = 0
		if pause_kind == 0:
			send_pauses_items_to_buttons_func()
		if(pauses.get_child(pause_kind).has_method("create_question")):
			pauses.get_child(pause_kind).set_numbers(_wave,_propedia_num)
			pauses.get_child(pause_kind).create_question()
		if(pauses.get_child(pause_kind).has_method("change_labels")):
			var stgMat = ""
			for i in range(1,_max_waves+1):
				stgMat += str(_propedia_num)+"x"+str(i)+"="+str(i*_propedia_num)+"\n"
			stgMat = stgMat.left(stgMat.length()-1)
			pauses.get_child(pause_kind).change_labels(str(_propedia_num),stgMat)
	_paused = !_paused
	if player.has_method("set_paused_status"):
		player.set_paused_status(_paused)

## This function should be connected to the resume button, it emits a signal to play an audio clip
## and calls the pauses function for the first pause choice
func _on_resume_button_pressed() -> void:
	play_button_sound.emit()
	pause(0)

## This function should be called by other scenes to change the number of the multiplication table
## the stage is on.
func change_propedia(num: int) -> void:
	_propedia_num = num

## This function should be used to change the enemies the game should spawn for this wave and also
## to increase the users statistics for the enemies beaten.
func set_wave_enemies(num: int) -> void:
	_enemies_left = num
	end_stats[TOTAL_ENEMIES_TEXT] += num

## This function should be used by the enemies so that when they die I can decrease the number
## of enemies left alive and notify the user
func decrease_enemy_number_by_one() -> void:
	_enemies_left_alive -= 1
	enemies_anouncer.text = str(_enemies_left_alive)

## This function should be used when the game needs to increase the wave count. When we do that
## we need to set how many enemies should spawn, announce the current stage and wave and voice
## that and then decrease the spawn timer wait time by the ammount of new enemies so that
## more enemies appear faster. Also if the user has passed the first wave we also show 
## the stage question for the user to answer
func _increase_wave() -> void:
	_wave += 1
	set_wave_enemies(_wave * _propedia_num)
	wave_announcer.text = str(_propedia_num)+"x"+str(_wave)
	#print_debug("changed wave")
	send_only_announcement.emit("Stage " + str(_propedia_num) + " Wave " + 
	str(_wave))
	wave_announcer.get_child(0).play("Appear")
	spawn_timer.wait_time = 1.0/(_wave*_propedia_num)
	if(_wave > 1):
		pause(1)

## This function should be used by the stage menu so that the game acquires a reference to it.
func read_stage_menu(menu: Node2D) -> void:
	stage_menu = menu

## This function should be used when the users tries to exit the game, dies or wins. First I try to
## to unlock the next stage of the game if the user has died and I delete the game scene. If there
## is not an exit game function on the stage menu then I quit the game.
func return_to_stage_menu() -> void:
	if(stage_menu.has_method("unlock_next_stage")):
		print_debug("Total enemies fought : " + str(end_stats[TOTAL_ENEMIES_TEXT]))
		print_debug("Total time needed : " + str(end_stats[TOTAL_TIME_TEXT]))
		print_debug("Total right answers : " + str(end_stats[CORRECT_ANSWERS_TEXT]) + 
		" and wrong ones : " + str(end_stats[WRONG_ANSWERS_TEXT]))
		stage_menu.unlock_next_stage(_propedia_num,end_stats, _user_died)
	if(stage_menu.has_method("exit_game")):
		queue_free()
		stage_menu.exit_game()
	else:
		get_tree().quit()

## This function should be conencted to the exit button. It emites the button sound signal, unpauses
## the game and informs the stage menu that the player died so that we don't enable the next stage.
func _on_exit_button_pressed() -> void:
	print_debug("Exit button pressed")
	play_button_sound.emit()
	pause(0)
	_user_died = true
	return_to_stage_menu()

## This function should be connected to the player's health depleted signal. It notifies that the
## player died and stops for 2 seconds after which we return to the main menu.
func _on_player_health_depleted() -> void:
	on_user_die.emit()
	_user_died = true
	await get_tree().create_timer(2.0).timeout
	return_to_stage_menu()

## This script should be called when the player picks up enemy drops. It notifies the player
## and then increases the level progress bar
func update_pickups(level: int, current_resources: int, res_to_lvl: int) -> void:
	items_announcer.text = str(level)
	level_bar.value = int((100 * current_resources)/res_to_lvl)
	#print_debug(res_to_lvl)

## This script should be called when the user answers one of the questions. It is called by
## the stage question object to pass the numbers answerd and the results. Firstly I unpause
## the scene, then depending on the result I increase the correct or false answers on the user's
## stats, I give the user the appropriate rewards, and for each power up or down I notify the player
func _on_stage_question_answer(_numbers: String, result: bool) -> void:
	pause(1)
	if result == true:
		end_stats[CORRECT_ANSWERS_TEXT] += 1
		var rwrd = randi_range(0,2)
		if(player.has_method("give_reward")):
			var stat_change: Array[String] = player.give_reward(rwrd)
			for change in stat_change:
				spawn_stat_notification(change + tr(INCREASED),Color.GREEN)
	else:
		end_stats[WRONG_ANSWERS_TEXT] += 1
		if(player.has_method("give_reward")):
			var stat_change: Array[String] = player.give_reward(-1)
			for change in stat_change:
				spawn_stat_notification(change + tr(DECREASED),Color.RED)
	send_only_announcement.emit("Stage " + str(_propedia_num) + " Wave " + str(_wave))

## This function should be connected to the multiplication table hint object so that when the user
## pressed the appropriate button, the hint gets hidden, we start the game music if it is
## stopped, and then we unpause the game.
func _on_stage_propedia_pressed_return() -> void:
	#game_music.playing = true
	#game_music.stream_paused = false
	if game_music.playing == false and game_music.stream_paused == false:
		game_music.play()
	pause(2)

## This function should be connected to the time timer, which keeps track of the user's time played.
## Every time it ticks, a second passes and we use this to calculate the exact seconds and minutes
## that have passed, and with the result we notify the user on screen.
func _on_time_timer_timeout() -> void:
	end_stats[TOTAL_TIME_TEXT] += 1
	
	#For deciseconds
	#var m = int(_total_time/600.0)
	#var s = int((_total_time - (m * 600))/10)
	#var d = _total_time - (s * 10) - (m * 600)
	
	var m = int(end_stats[TOTAL_TIME_TEXT]/60.0)
	var s = end_stats[TOTAL_TIME_TEXT] - (m*60)
	game_timer.text = '%02d:%02d' % [m,s]

## This function returns a reference to the stage question object in the game. It should be used by
## other scenes appropriately.
func get_stage_quest():
	return pauses.get_child(1)

## This function sets the max waves number into a specific value. This should be used by other
## to change how many waves the game has.
func set_max_waves(num: int) -> void:
	_max_waves = num

## This function should be called when the player gains a level. It needs the changes made,
## along with the color that depends on if the changes are good or not and the current level.
## Using the changes and the color it spawns a new notification for the user to detail the changes
## sets the level of the player on the end stats and signals that the player levels up.
func _player_lvlup(change: String, clr: Color, lvl: int) -> void:
	spawn_stat_notification(change, clr)
	end_stats[LEVEL_TEXT] = lvl
	on_player_leveled_up.emit()

## This function should be connected to the signal made by the player when they make a step. It
## passes the signal to the main menu so that the appropriate sound is made.
func _emit_on_step_made() -> void:
	on_step_made.emit()

## This function should be connected to the signal made by the gun when it fires. It
## passes the signal to the main menu so that the appropriate sound is made.
func _emit_shoot_signal() -> void:
	on_shoot_performed.emit()

## This function should be connected to the signal made by the player when they pick up a drop. It
## passes the signal to the main menu so that the appropriate sound is made.
func _emit_player_pickup_signal() -> void:
	on_player_item_picked_up.emit()

## This function should be emmited when the user increases any of it's stats. It
## passes the signal to the main menu so that the appropriate sound is made.
func _emit_player_rewarded(powered: bool) -> void:
	on_player_rewarded.emit(powered)

## This function should be connected to the audio button, it emits a signal for the main menu
## so that the audio menu shows up.
func _on_audio_button_pressed() -> void:
	show_audio_frame.emit()

## This function should be called by the stage question object on the scene if the user answers
## wrong too many times. It shows the multiplication table hint from the start of the stage.
func _on_too_many_wrong_answers() -> void:
	pause(2)

## This function sends the player and all pause children to the tts component so that the
## appropriate signals are connencted. After that we inform the pause child that it should voice
## the multiplication table hint if it has that method.
func setup_pauses_and_player() -> void:
	send_scene_for_signals.emit(player)
	for paus in pauses.get_children():
		send_scene_for_signals.emit(paus)
		if paus.has_method("call_material"):
			paus.call_material()

## This function sends the buttons of the pause menu to the tts component with the announcement
## that the game has paused. It should be called when the game gets regularly paused.
func send_pauses_items_to_buttons_func() -> void:
	send_interactive_items.emit(pause_interactive_item_arrray,pause_text_for_interactive_items,"Game Paused")
