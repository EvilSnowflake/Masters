extends Node2D

const CHANGED_STATS_LABEL = preload("res://scenes/changed_stats_label.tscn")

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
@onready var time_timer = %Time_Timer
@onready var game_timer = %Game_Timer

@export var _propedia_num: int = 1
@export var _enemies_left: int = 0
@export var _enemies_left_alive: int = 0
@export var _wave: int = 0

var _user_died = false
var _max_waves: int = 10
var stage_menu
var _paused: bool = false
var end_stats : Dictionary = {
	"total_enemies" = 0.0,
	"total_time" = 0.0,
	"correct_answers" = 0.0,
	"wrong_answers" = 0.0,
	"level" = 0.0
}

signal play_button_sound()
signal on_step_made()
signal on_shoot_performed()
signal on_player_item_picked_up()
signal on_player_leveled_up()
signal on_user_die()
signal on_player_rewarded(powered: bool)

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
	

func _process(_delta):
	if(Input.is_action_just_pressed("Escape")):
		pause(0)
	if(_user_died):
		game_music.set_volume_db(game_music.volume_db - 20*_delta)

func spawn_enemy() -> void:
	var new_mob = preload("res://scenes/enemy.tscn").instantiate()
	path_follow_2d.progress_ratio = randf()
	new_mob.global_position = path_follow_2d.global_position
	add_child(new_mob)
	if(new_mob.has_method("set_game")):
		new_mob.set_game(self)
		

func spawn_stat_notification(message: String, color: Color) -> void:
	var new_notification: Label = CHANGED_STATS_LABEL.instantiate()
	statistics_container.add_child(new_notification)
	new_notification.set("theme_override_colors/font_color",color)
	new_notification.text = message

func _on_spawn_timer_timeout() -> void:
	if(_enemies_left > 0):
		spawn_enemy()
		_enemies_left -= 1
		_enemies_left_alive += 1
		enemies_anouncer.text = "ENEMIES LEFT: " + str(_enemies_left_alive)
	
	if(_enemies_left_alive == 0):
		spawn_timer.stop()
		await get_tree().create_timer(2.0).timeout
		if(_wave < _max_waves):
			_increase_wave()
			spawn_timer.start()
			return
			
		return_to_stage_menu()

func pause(pause_kind: int) -> void:
	
	if(_paused):
		if(pause_kind == 0):
			game_music.stream_paused = false
		pauses.get_child(pause_kind).hide()
		time_timer.start()
		Engine.time_scale = 1
	else:
		if(pause_kind == 0):
			game_music.stream_paused = true
		pauses.get_child(pause_kind).show()
		time_timer.stop()
		Engine.time_scale = 0
		if(pauses.get_child(pause_kind).has_method("create_question")):
			pauses.get_child(pause_kind).set_numbers(_wave,_propedia_num)
			pauses.get_child(pause_kind).create_question()
		if(pauses.get_child(pause_kind).has_method("change_labels")):
			var stgMat = ""
			for i in range(1,_max_waves+1):
				stgMat += str(_propedia_num)+"x"+str(i)+"="+str(i*_propedia_num)+"|"
			stgMat = stgMat.left(stgMat.length()-1)
			pauses.get_child(pause_kind).change_labels(str(_propedia_num),stgMat)
	_paused = !_paused
	if player.has_method("set_paused_status"):
		player.set_paused_status(_paused)

func _on_resume_button_pressed() -> void:
	play_button_sound.emit()
	pause(0)

func change_propedia(num: int) -> void:
	_propedia_num = num

func set_wave_enemies(num: int) -> void:
	_enemies_left = num
	end_stats["total_enemies"] += num

func decrease_enemy_number_by_one():
	_enemies_left_alive -= 1
	enemies_anouncer.text = "ENEMIES LEFT: " + str(_enemies_left_alive)

func _increase_wave() -> void:
	_wave += 1
	set_wave_enemies(_wave * _propedia_num)
	wave_announcer.text = str(_propedia_num)+"x"+str(_wave)
	wave_announcer.get_child(0).play("Appear")
	spawn_timer.wait_time = 1.0/(_wave*_propedia_num)
	if(_wave > 1):
		pause(1)

func read_stage_menu(menu: Node2D) -> void:
	stage_menu = menu

func return_to_stage_menu() -> void:
	if(stage_menu.has_method("unlock_next_stage")):
		print_debug("Total enemies fought : " + str(end_stats["total_enemies"]))
		print_debug("Total time needed : " + str(end_stats["total_time"]))
		print_debug("Total right answers : " + str(end_stats["correct_answers"]) + " and wrong ones : " + str(end_stats["wrong_answers"]))
		stage_menu.unlock_next_stage(_propedia_num,end_stats, _user_died)
	if(stage_menu.has_method("exit_game")):
		queue_free()
		stage_menu.exit_game()
	else:
		get_tree().quit()

func _on_exit_button_pressed() -> void:
	print_debug("Exit button pressed")
	play_button_sound.emit()
	pause(0)
	_user_died = true
	return_to_stage_menu()


func _on_player_health_depleted() -> void:
	on_user_die.emit()
	_user_died = true
	await get_tree().create_timer(2.0).timeout
	return_to_stage_menu()

func update_pickups(level: int, current_resources: int, res_to_lvl: int) -> void:
	items_announcer.text = "LEVEL: " + str(level)
	level_bar.value = int((100 * current_resources)/res_to_lvl)
	print_debug(res_to_lvl)

func _on_stage_question_answer(_numbers: String, result: bool) -> void:
	pause(1)
	if result == true:
		end_stats["correct_answers"] += 1
		var rwrd = randi_range(0,2)
		if(player.has_method("give_reward")):
			var stat_change: Array[String] = player.give_reward(rwrd)
			for change in stat_change:
				spawn_stat_notification(change + " INCREASED!",Color.GREEN)
	else:
		end_stats["wrong_answers"] += 1
		if(player.has_method("give_reward")):
			var stat_change: Array[String] = player.give_reward(-1)
			for change in stat_change:
				spawn_stat_notification(change + " DECREASED!",Color.RED)
		

func _on_stage_propedia_pressed_return() -> void:
	game_music.playing = true
	pause(2)

func _on_time_timer_timeout() -> void:
	end_stats["total_time"] += 1
	
	#For deciseconds
	#var m = int(_total_time/600.0)
	#var s = int((_total_time - (m * 600))/10)
	#var d = _total_time - (s * 10) - (m * 600)
	
	var m = int(end_stats["total_time"]/60.0)
	var s = end_stats["total_time"] - (m*60)
	game_timer.text = '%02d:%02d' % [m,s]

func get_stage_quest():
	return pauses.get_child(1)

func set_max_waves(num: int) -> void:
	_max_waves = num

func _player_lvlup(change: String, clr: Color, lvl: int) -> void:
	spawn_stat_notification(change, clr)
	end_stats["level"] = lvl
	on_player_leveled_up.emit()

func _emit_on_step_made() -> void:
	on_step_made.emit()
	
func _emit_shoot_signal() -> void:
	on_shoot_performed.emit()

func _emit_player_pickup_signal() -> void:
	on_player_item_picked_up.emit()

func _emit_player_rewarded(powered: bool) -> void:
	on_player_rewarded.emit(powered)
