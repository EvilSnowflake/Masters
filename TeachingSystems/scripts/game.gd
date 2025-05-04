extends Node2D

const CHANGED_STATS_LABEL = preload("res://scenes/changed_stats_label.tscn")
const STAGE_MATERIALS = ["1x1 = 1 | 1x2 = 2 | 1x3 = 3 | 1x4 = 4 | 1x5 = 5 | 1x6 = 6 | 1x7 = 7 | 1x8 = 8 | 1x9 = 9 | 1x10 = 10","2x1 = 2 | 2x2 = 4 | 2x3 = 6 | 2x4 = 8 | 2x5 = 10 | 2x6 = 12 | 2x7 = 14 | 2x8 = 16 | 2x9 = 18 | 2x10 = 20", "3x1 = 3 | 3x2 = 6 | 3x3 = 9 | 3x4 = 12 | 3x5 = 15 | 3x6 = 18 | 3x7 = 21 | 3x8 = 24 | 3x9 = 27 | 3x10 = 30", "4x1 = 4 | 4x2 = 8 | 4x3 = 12 | 4x4 = 16 | 4x5 = 20 | 4x6 = 24 | 4x7 = 28 | 4x8 = 32 | 4x9 = 36 | 4x10 = 40", "5x1 = 5 | 5x2 = 10 | 5x3 = 15 | 5x4 = 20 | 5x5 = 25 | 5x6 = 30 | 5x7 = 35 | 5x8 = 40 | 5x9 = 45 | 5x10 = 50", "6x1 = 6 | 6x2 = 12 | 6x3 = 18 | 6x4 = 24 | 6x5 = 30 | 6x6 = 36 | 6x7 = 42 | 6x8 = 48 | 6x9 = 54 | 6x10 = 60", "7x1 = 7 | 7x2 = 14 | 7x3 = 21 | 7x4 = 28 | 7x5 = 35 | 7x6 = 42 | 7x7 = 49 | 7x8 = 56 | 7x9 = 63 | 7x10 = 70", "8x1 = 8 | 8x2 = 16 | 8x3 = 24 | 8x4 = 32 | 8x5 = 40 | 8x6 = 48 | 8x7 = 56 | 8x8 = 64 | 8x9 = 72 | 8x10 = 80", "9x1 = 9 | 9x2 = 18 | 9x3 = 27 | 9x4 = 36 | 9x5 = 45 | 9x6 = 54 | 9x7 = 63 | 9x8 = 72 | 9x9 = 81 | 9x10 = 90", "10x1 = 10 | 10x2 = 20 | 10x3 = 30 | 10x4 = 40 | 10x5 = 50 | 10x6 = 60 | 10x7 = 70 | 10x8 = 80 | 10x9 = 90 | 9x10 = 100"]

@onready var path_follow_2d = %PathFollow2D
@onready var spawn_timer = %Spawn_Timer
@onready var wave_announcer = %Wave_Announcer
@onready var player = $Player
@onready var enemies_anouncer = %Enemies_Announcer
@onready var items_announcer = %Items_Announcer
@onready var level_bar = %Level_Bar
@onready var pauses = %Pauses
@onready var statistics_container = %Statistics_Container
@onready var game_music = %Game_Music

@export var _propedia_num: int = 1
@export var _enemies_left: int = 0
@export var _enemies_left_alive: int = 0
@export var _wave: int = 0

var _user_died = false
var _max_waves: int = 10
var stage_menu
var _paused: bool = false

func _ready():
	spawn_timer.start()

func _process(_delta):
	if(Input.is_action_just_pressed("Escape")):
		pause(0)
	if(_user_died):
		game_music.set_volume_db(game_music.volume_db - 20*_delta)

func spawn_enemy():
	var new_mob = preload("res://scenes/enemy.tscn").instantiate()
	path_follow_2d.progress_ratio = randf()
	new_mob.global_position = path_follow_2d.global_position
	add_child(new_mob)
	if(new_mob.has_method("set_game")):
		new_mob.set_game(self)

func spawn_stat_notification(message: String, color: Color):
	var new_notification: Label = CHANGED_STATS_LABEL.instantiate()
	statistics_container.add_child(new_notification)
	new_notification.set("theme_override_colors/font_color",color)
	new_notification.text = message

func _on_spawn_timer_timeout():
	if(_enemies_left > 0):
		spawn_enemy()
		_enemies_left -= 1
		_enemies_left_alive += 1
		enemies_anouncer.text = "Enemies left: " + str(_enemies_left_alive)
	
	if(_enemies_left_alive == 0):
		spawn_timer.stop()
		await get_tree().create_timer(2.0).timeout
		if(_wave < _max_waves):
			_increase_wave()
			spawn_timer.start()
			return
			
		return_to_stage_menu()

func pause(pause_kind: int):
	if(_paused):
		if(pause_kind == 0):
			game_music.stream_paused = false
		pauses.get_child(pause_kind).hide()
		Engine.time_scale = 1
	else:
		if(pause_kind == 0):
			game_music.stream_paused = true
		pauses.get_child(pause_kind).show()
		Engine.time_scale = 0
		if(pauses.get_child(pause_kind).has_method("create_question")):
			pauses.get_child(pause_kind).set_numbers(_wave,_propedia_num)
			pauses.get_child(pause_kind).create_question()
		if(pauses.get_child(pause_kind).has_method("change_labels")):
			pauses.get_child(pause_kind).change_labels(str(_propedia_num),STAGE_MATERIALS[_propedia_num - 1])
	_paused = !_paused

func _on_resume_button_pressed():
	pause(0)

func change_propedia(num: int):
	_propedia_num = num

func set_wave_enemies(num: int):
	_enemies_left = num

func decrease_enemy_number_by_one():
	_enemies_left_alive -= 1
	enemies_anouncer.text = "Enemies left: " + str(_enemies_left_alive)

func _increase_wave():
	_wave += 1
	set_wave_enemies(_wave * _propedia_num)
	wave_announcer.text = str(_propedia_num)+"x"+str(_wave)
	wave_announcer.get_child(0).play("Appear")
	if(_wave > 1):
		pause(1)

func read_stage_menu(menu: Node2D):
	stage_menu = menu

func return_to_stage_menu():
	if(_wave == _max_waves and stage_menu.has_method("unlock_next_stage") and !_user_died):
		stage_menu.unlock_next_stage(_propedia_num)
	if(stage_menu.has_method("exit_game")):
		queue_free()
		stage_menu.exit_game()
	else:
		get_tree().quit()

func _on_exit_button_pressed():
	pause(0)
	_user_died = true
	return_to_stage_menu()


func _on_player_health_depleted():
	_user_died = true
	await get_tree().create_timer(2.0).timeout
	return_to_stage_menu()

func update_pickups(level: int, current_resources: int, res_to_lvl: int):
	items_announcer.text = "Level: " + str(level)
	level_bar.value = int((100 * current_resources)/res_to_lvl)

func _on_stage_question_correct_answer():
	pause(1)
	var rwrd = randi_range(0,2)
	if(player.has_method("give_reward")):
		var stat_change: Array[String] = player.give_reward(rwrd)
		for change in stat_change:
			spawn_stat_notification(change + " INCREASED!",Color.GREEN)

func _on_stage_question_wrong_answer():
	pause(1)
	if(player.has_method("give_reward")):
		var stat_change: Array[String] = player.give_reward(-1)
		for change in stat_change:
			spawn_stat_notification(change + " DECREASED!",Color.RED)

func _on_stage_propedia_pressed_return():
	game_music.playing = true
	pause(2)
