extends Control

const REGISTERSCENE = "res://scenes/register_scene.tscn"
const LOGINSCENE = "res://scenes/login_screen.tscn"
const LEADERBOARDSCENE = "res://scenes/leaderboard_scene.tscn"
const STAGE_BUTTON = preload("res://scenes/stage_button.tscn")
const STAGE_BUTTON_BOX = preload("res://scenes/stage_button_box.tscn")
const HTTPS_API_URL: String = "https://localhost:7218/api/Numbers/2"
const API_URL: String = "http://localhost:5000/api/Numbers/1"
const STAGE_PREFIX: String = "stage_"
const LANGUAGE_TEXT: String = "language"
const ENGLISH_LOC: String = "en"
const GREEK_LOC: String = "el"
const SCORE_TEXT: String = "score"
const HIGHSCORE_TEXT: String = "highscore"
const ANSWERS_TEXT: String = "answers"
const SOUND_TEXT: String = "sound"
const MASTER_TEXT: String = "master"
const MUSIC_TEXT: String = "music"
const SFX_TEXT: String = "sfx"
const LOGGING_IN: String = "LOGGING_IN_TEXT"
const LOGGED_IN_AS: String = "LOGGED_IN_TEXT"
const NOT_LOGGED_IN: String = "NOT_LOGGED_IN_TEXT"
const LOADING_DATA: String = "LOADING_DATA_TEXT"
const SAVING_DATA: String = "SAVING_DATA_TEXT"
const SAVING_HIGHSCORE: String = "SAVING_HIGHSCORE_TEXT"
const ENGLISH: String = "ENGLISH_WORD"
const GREEK: String = "GREEK_WORD"


#FILE SAVE ON %APPDATA%\Godot\app_userdata\TeachingSystems
var stage_menu
var save_path = "user://SavedData.save"
var _game_stats : Dictionary = {}
var _current_game: Object
var _audio_options: Control
var _rebind_menu: Control

@export var max_num_stage_buttons = 7
@export var stage_buttons: Array[Button] = []
@export var num_of_stages = 10
@export var num_in_propedia = 10
@export var _codes: Array[String] = ["12345678910","2468101214161820","36912151821242730","481216202428323640","5101520253035404550","6121824303642485460","7142128354249566370","8162432404856647280","9182736455463728190","102030405060708090100"]
@export var statistics_scn: Control
@export var audio_options_button: Button
@export var rebind_button: Button
@export var locale_options: OptionButton

@onready var _register_button =  $MarginContainer/HBoxContainer/TitleItems/HBoxContainer2/Register
@onready var _login_button = $MarginContainer/HBoxContainer/TitleItems/HBoxContainer2/Login
@onready var controls = %Controls
@onready var code_input = %Code_Input
@onready var login_state_label = $MarginContainer/HBoxContainer/TitleItems/PlayerLoginLabel
@onready var _logout_button = $MarginContainer/HBoxContainer/TitleItems/Logout
@onready var stage_box_container = $MarginContainer/HBoxContainer/MarginContainer/StageBoxContainer
@onready var _save_data_button = $MarginContainer/HBoxContainer/TitleItems/HBoxContainer3/SaveData
@onready var _load_data_button = $MarginContainer/HBoxContainer/TitleItems/HBoxContainer3/LoadData
@onready var _leaderboard_button = $MarginContainer/HBoxContainer/TitleItems/Leaderboards
@onready var _number_req_https = $NumberRequests
@onready var _statistics_button = $MarginContainer/HBoxContainer/TitleItems/Statistics
@onready var button_sounds = %ButtonAudioPlayer
@onready var anti_click_panel = %AntiClickPanel
@onready var wait_timer = %WaitTimer
@onready var info_label: Label = %InfoLabel
@onready var shoot_audio_player: AudioStreamPlayer2D = %ShootAudioPlayer
@onready var pickup_audio_player: AudioStreamPlayer2D = %PickupAudioPlayer
@onready var poweredown_audio_player: AudioStreamPlayer2D = %PoweredownAudioPlayer
@onready var powerup_audio_player: AudioStreamPlayer2D = %PowerupAudioPlayer
@onready var step_audio_player: AudioStreamPlayer2D = %StepAudioPlayer
@onready var user_killed_audio_player: AudioStreamPlayer2D = %UserKilledAudioPlayer
@onready var slider_audio_player: AudioStreamPlayer2D = %SliderAudioPlayer


signal play_button_sound()
signal show_anti_click()

func _ready():
	play_button_sound.connect(_on_button_play_sound)
	show_anti_click.connect(_on_anticlick_called)
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	if(controls.has_signal("play_button_sound")):
		controls.play_button_sound.connect(_on_button_play_sound)
	if(statistics_scn.has_signal("play_button_sound")):
		statistics_scn.play_button_sound.connect(_on_button_play_sound)
	
	#API STUFF
	_number_req_https.request_completed.connect(_on_request_completed)
	_number_req_https.request(API_URL)
	
	_register_button.pressed.connect(_on_register_button_pressed.bind())
	_login_button.pressed.connect(_on_login_button_pressed.bind())
	_logout_button.pressed.connect(_on_logout_button_pressed)
	_save_data_button.pressed.connect(_on_cloud_save_data_pressed)
	_load_data_button.pressed.connect(_on_cloud_load_button_pressed)
	_leaderboard_button.pressed.connect(_on_leader_button_pressed)
	_statistics_button.pressed.connect(_enableStatsScreen)
	if rebind_button != null:
		rebind_button.pressed.connect(_on_rebind_button_pressed)
	if locale_options != null:
		locale_options.item_selected.connect(_on_locale_options_item_selected)
	load_data()
	

	
	#_game_stats["highscore"] = _calc_highscore()
	
	#SILENTWOLF STTUFF
	SilentWolf.Auth.sw_session_check_complete.connect(_on_login_complete)
	SilentWolf.Auth.sw_login_complete.connect(_on_login_complete)
	SilentWolf.Auth.sw_logout_complete.connect(_on_logout_complete)
	SilentWolf.Auth.auto_login_player()
	info_label.text = tr(LOGGING_IN)
	#unlock_enabled_stages()
	


func _on_stage_button_pressed(stg_num: String) -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	
	if(stage_menu.has_method("create_game")):
		_current_game = stage_menu.create_game(int(stg_num),num_in_propedia)
		if _current_game.has_method("get_stage_quest"):
			var stg_qst = _current_game.get_stage_quest()
			if stg_qst.has_signal("answer_given"):
				stg_qst.answer_given.connect(_update_answrs)
				#stg_qst.correct_answer.connect(_update_answrs)
				#print_debug(stg_qst.answer_given.get_connections())
			if ("menu_screen_node" in stg_qst):
				stg_qst.menu_screen_node = self
			if ("max_num" in stg_qst):
				stg_qst.max_num = num_of_stages
			if ("num_in_propedia" in stg_qst):
				stg_qst.num_in_propedia = num_in_propedia
			if (stg_qst.has_signal("play_button_sound")):
				stg_qst.play_button_sound.connect(_on_button_play_sound)
		if _current_game.has_signal("play_button_sound"):
			_current_game.play_button_sound.connect(_on_button_play_sound)
		if _current_game.has_signal("on_step_made"):
			_current_game.on_step_made.connect(_play_step_sound)
		if _current_game.has_signal("on_shoot_performed"):
			_current_game.on_shoot_performed.connect(_play_shoot_sound)
		if _current_game.has_signal("on_player_leveled_up"):
			_current_game.on_player_leveled_up.connect(_play_levelup_sound)
		if _current_game.has_signal("on_player_item_picked_up"):
			_current_game.on_player_item_picked_up.connect(_play_pickup_sound)
		if _current_game.has_signal("on_user_die"):
			_current_game.on_user_die.connect(_play_on_die_sound)
		if _current_game.has_signal("on_player_rewarded"):
			_current_game.on_player_rewarded.connect(_play_rewarded_sound)
		if _current_game.has_signal("show_audio_frame"):
			_current_game.show_audio_frame.connect(_on_audio_options_button_pressed)

func enable_propedia_button(num: int, end_stats : Dictionary = {}, user_died: bool = false) -> void:
	#print_debug("Enabling stage "+str(num))
	if not user_died:
		end_stats[SCORE_TEXT] = find_the_score(end_stats)
		
	else:
		if not _game_stats.has(STAGE_PREFIX+str(num)):
			end_stats[SCORE_TEXT] = 0
		elif _game_stats.has(STAGE_PREFIX+str(num)) and _game_stats[STAGE_PREFIX+str(num)].has(SCORE_TEXT):
			if _game_stats[STAGE_PREFIX+str(num)][SCORE_TEXT] > 0:
				var new_score = find_the_score(end_stats)
				if new_score < _game_stats[STAGE_PREFIX+str(num)][SCORE_TEXT]:
					return
				else:
					end_stats[SCORE_TEXT] = new_score
		elif _game_stats.has(STAGE_PREFIX+str(num)) and not _game_stats[STAGE_PREFIX+str(num)].has(SCORE_TEXT):
			end_stats[SCORE_TEXT] = 0
			
	
	_game_stats[STAGE_PREFIX+str(num)] = end_stats
	_game_stats[HIGHSCORE_TEXT] = _calc_highscore()
	#_stages_en[num] = 1
	_cloud_save_data()
	unlock_enabled_stages()

func _on_controls_button_pressed() -> void:
	play_button_sound.emit()
	controls.show()

func _on_exit_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().quit()

func unlock_enabled_stages() -> void:
	for i in range(num_of_stages):
		if i == 0:
			stage_buttons[i].disabled = false
			continue
		if not _game_stats.has(STAGE_PREFIX+str(i)):
			stage_buttons[i].disabled = true
			continue
		if not _game_stats[STAGE_PREFIX+str(i)].has(SCORE_TEXT):
			stage_buttons[i].disabled = true
			continue
		if _game_stats[STAGE_PREFIX+str(i)][SCORE_TEXT] <= 0:
			stage_buttons[i].disabled = true
			continue
		stage_buttons[i].disabled = false
		
		#if _game_stats.has(STAGE_PREFIX+str(i)):
		#	stage_buttons[i+1].disabled = false

func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var jstr = JSON.stringify(_game_stats)
	file.store_line(jstr)
	print_debug(_game_stats)
	#file.store_line(jstr)
	print_debug("SAVED!")

func load_data() -> void:
	var file = FileAccess.open(save_path,FileAccess.READ)
	if not file:
		print_debug("No File")
		return
	if file == null:
		print_debug("File Empty")
		return
	if(FileAccess.file_exists(save_path) and not file.eof_reached()):
		print_debug("Found Stats")
		var current_line = JSON.parse_string(file.get_line())
		if current_line:
			_game_stats = current_line
		print_debug(_game_stats)
		_setup_audio_settings()
		_setup_rebind_settings()
		_setup_locale()
		#_stages_en = file.get_var()
		
	else:
		print_debug("NO SAVED DATA FOUND!")

func delete_data() -> void:
	if(FileAccess.file_exists(save_path)):
		_game_stats = {}
		save_data()
		_cloud_save_data()
		#stages_enabled = 1
		#for i in range(len(_stages_en)):
		#	if(i == 0):
		#		_stages_en[i] = 1
		#	else:
		#		_stages_en[i] =0
		#file.store_var(_stages_en)
		unlock_enabled_stages()
		print_debug("PROGRESS DELETED!")
		
func _on_clear_data_pressed() -> void:
	play_button_sound.emit()
	delete_data()

func _on_code_button_pressed() -> void:
	var code_text = code_input.text
	for i in range(len(_codes)):
		if(_codes[i] == code_text):
			enable_propedia_button(i+1)
	code_input.clear()

func _on_register_button_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(REGISTERSCENE)

func _on_login_button_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(LOGINSCENE)

func _on_login_complete(_sw_result) -> void:
	info_label.text = ""
	update_login_state_label()

func _on_logout_button_pressed() -> void:
	play_button_sound.emit()
	SilentWolf.Auth.logout_player()

func _on_logout_complete(_a,_b) -> void:
	update_login_state_label()

func _on_leader_button_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(LEADERBOARDSCENE)

func update_login_state_label() -> void:
	if SilentWolf.Auth.logged_in_player:
		var username = SilentWolf.Auth.logged_in_player
		login_state_label.text = LOGGED_IN_AS + username
		_cloud_load_data()
		_logout_button.show()
		_save_data_button.show()
		_load_data_button.show()
		_leaderboard_button.show()
		_login_button.hide()
	else:
		login_state_label.text = NOT_LOGGED_IN
		_logout_button.hide()
		_save_data_button.hide()
		_load_data_button.hide()
		_login_button.show()

func _add_stage_and_button(number: int, button_num: int) -> int:
	var stage_box = STAGE_BUTTON_BOX.instantiate()
	stage_box_container.add_child(stage_box)
	for i in range(number):
		var stage : Button = STAGE_BUTTON.instantiate()
		stage.text = str(button_num+1)
		stage_box.add_child(stage)
		stage_buttons.append(stage)
		#_stages_en.append(0)
		button_num += 1
	return button_num

func _update_answrs(numbers: String, result: bool) -> void:
	if not _game_stats.has(ANSWERS_TEXT):
		_game_stats[ANSWERS_TEXT] = {}
	_game_stats[ANSWERS_TEXT][numbers] = result

func _on_cloud_load_button_pressed() -> void:
	play_button_sound.emit()
	_cloud_load_data()

func _cloud_load_data() -> void:
	if SilentWolf.Auth.logged_in_player:
		print_debug("Loading data from cloud")
		info_label.text = tr(LOADING_DATA)
		
		#load data async
		var sw_result = await SilentWolf.Players.get_player_data(SilentWolf.Auth.logged_in_player).sw_get_player_data_complete
		print_debug("Player data from cloud: " + str(sw_result.player_data))
		
		#show results
		if sw_result and sw_result.success and sw_result.player_data:
			_game_stats.merge(sw_result.player_data)
			save_data()
			_cloud_save_data()
			unlock_enabled_stages()
			_setup_audio_settings()
			_setup_rebind_settings()
			_setup_locale()
			print_debug("Found data on cloud")
		else:
			print_debug("Load failed from cloud")
		info_label.text = ""

func _on_cloud_save_data_pressed() -> void:
	play_button_sound.emit()
	_cloud_save_data()

func _cloud_save_data() -> void:
	save_data()
	if SilentWolf.Auth.logged_in_player:
		info_label.text = tr(SAVING_DATA)
		print_debug("Saving to cloud")
		var sw_result = await SilentWolf.Players.save_player_data(SilentWolf.Auth.logged_in_player, _game_stats).sw_save_player_data_complete
		if(sw_result and sw_result.success):
			print_debug("Saved to cloud")
			upload_lead_score()
		else:
			print_debug("Save failed")
		info_label.text = ""

func find_the_score(stats: Dictionary) -> int:
	var score = 0
	if stats == {}:
		print_debug("Empty stats")
		return score
	var total_en: int = stats["total_enemies"]
	var total_t: int = stats["total_time"]
	var total_corr: int = stats["correct_answers"]
	var total_wrng: int = stats["wrong_answers"]
	var total_lvl: int = stats["level"]
	var time_for_en: int = 3
	var points_for_answ: int = 5
	var points_for_wrng_answ: int = 2
	var points_for_lvl: int = 1
	var expctd: int = total_en * time_for_en
	var base_score: int = num_of_stages*num_of_stages
	
	score = base_score + (total_corr*points_for_answ) - (total_wrng*points_for_wrng_answ) + (points_for_lvl*total_lvl)
	if total_t < expctd:
		score += expctd-total_t
	
	return score

func upload_lead_score():
	if not _game_stats.has(HIGHSCORE_TEXT) or not SilentWolf.Auth.logged_in_player:
		return
	var sw_result = await SilentWolf.Scores.get_top_score_by_player(SilentWolf.Auth.logged_in_player).sw_top_player_score_complete
	print_debug(sw_result)
	if sw_result == null:
		return
	print_debug(sw_result["top_score"][SCORE_TEXT])
	print_debug(_game_stats[HIGHSCORE_TEXT])
	if sw_result["top_score"][SCORE_TEXT] >= _game_stats[HIGHSCORE_TEXT]:
		print_debug("Highscore has not changed or improved")
		return
	info_label.text = tr(SAVING_HIGHSCORE)
	var sw_score_result: Dictionary = await SilentWolf.Scores.save_score(SilentWolf.Auth.logged_in_player, _game_stats[HIGHSCORE_TEXT]).sw_save_score_complete
	info_label.text = ""
	print_debug("Score persisted successfully: " + str(sw_score_result.score_id))

func _calc_highscore() -> int:
	var score: int = 0
	for stat : String in _game_stats:
		if stat.begins_with("stage"):
			if _game_stats[stat].has(SCORE_TEXT):
				score += _game_stats[stat][SCORE_TEXT]
	
	return score

func _on_request_completed(result,_response_code,_headers,body) -> void:
	#print_debug("Request result : "+str(result))
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print_debug("Data found from the api")
		num_of_stages = int(json["numberOne"])
		num_in_propedia = int(json["numberTwo"])
		setupButtons()
	else:
		setupButtons()
	
func setupButtons() -> void:
	if(stage_box_container.get_child_count() > 0):
		print_debug("Buttons found, operation stopped")
		return
	var rest = int(num_of_stages)%7
	var numOfTimes = floor(num_of_stages/max_num_stage_buttons)
	var button_num = 0
	while numOfTimes > 0:
		button_num = _add_stage_and_button(max_num_stage_buttons,button_num)
		numOfTimes -= 1
	button_num = _add_stage_and_button(rest,button_num)
	stage_menu = get_tree().get_root().get_node("Stage_Menu")
	
	#BUTTONS STUFF
	for button in stage_buttons:
		button.pressed.connect(_on_stage_button_pressed.bind(button.text))
	unlock_enabled_stages()

func _setup_audio_settings() -> void:
	if _audio_options == null:
		print_debug("No audio options provided")
		return
	if _audio_options.has_method("initialiase_values"):
		_audio_options.initialiase_values()
	if _audio_options.has_method("load_values") and _game_stats.has(SOUND_TEXT):
		_audio_options.load_values(_game_stats[SOUND_TEXT][MASTER_TEXT],_game_stats[SOUND_TEXT][MUSIC_TEXT],_game_stats[SOUND_TEXT][SFX_TEXT])

func _setup_rebind_settings() -> void:
	if _rebind_menu == null:
		print_debug("No rebind menu provided")
		return
	if _game_stats.has("rebinds"):
		for rebind in _game_stats["rebinds"]:
			if _rebind_menu.has_method("change_input"):
				_rebind_menu.change_input(rebind, _game_stats["rebinds"][rebind])

func _setup_locale() -> void:
	if not _game_stats.has(LANGUAGE_TEXT):
		print_debug("No saved locale option")
		TranslationServer.set_locale(ENGLISH_LOC)
	else:
		match _game_stats[LANGUAGE_TEXT]:
			ENGLISH_LOC:
				locale_options.selected = 0
			GREEK_LOC:
				locale_options.selected = 1
		TranslationServer.set_locale(_game_stats[LANGUAGE_TEXT])

func _enableStatsScreen() -> void:
	play_button_sound.emit()
	if(statistics_scn != null and statistics_scn.has_method("set_player_stats") and statistics_scn.has_method("set_stages_button_up") and statistics_scn.has_method("set_num_of_stages") and statistics_scn.has_method("set_num_in_propedia")):
		statistics_scn.set_player_stats(_game_stats)
		statistics_scn.set_stages_button_up()
		statistics_scn.set_num_of_stages(num_of_stages)
		statistics_scn.set_num_in_propedia(num_of_stages)
		statistics_scn.show()
		
func _on_button_play_sound() -> void:
	button_sounds.play()
	
func _on_slider_value_changed_sound() -> void:
	slider_audio_player.play()
	
func _on_anticlick_called() -> void:
	anti_click_panel.show()

func _on_wait_timer_timeout() -> void:
	anti_click_panel.hide()

func _play_step_sound() -> void:
	step_audio_player.play()

func _play_shoot_sound() -> void:
	shoot_audio_player.play()

func _play_pickup_sound() -> void:
	pickup_audio_player.play()

func _play_levelup_sound() -> void:
	print_debug("Make levelup sound!")

func _play_on_die_sound() -> void:
	user_killed_audio_player.play()

func _play_rewarded_sound(powered: bool) -> void:
	if powered:
		powerup_audio_player.play()
	else:
		poweredown_audio_player.play()

func _on_audio_options_button_pressed():
	play_button_sound.emit()
	_audio_options.show()

func set_audio_options(opt: Control) -> void:
	if opt == null:
		print_debug("No options panel given!")
		return
	_audio_options = opt
	audio_options_button.pressed.connect(_on_audio_options_button_pressed)
	_setup_audio_settings()
	if _audio_options.has_signal("audio_values_changed"):
		_audio_options.audio_values_changed.connect(_on_audio_values_changed)
	if _audio_options.has_signal("on_button_pressed"):
		_audio_options.on_button_pressed.connect(_on_button_play_sound)
	if _audio_options.has_signal("sliders_value_change"):
		_audio_options.sliders_value_change.connect(_on_slider_value_changed_sound)

func set_rebind_menu(reb: Control) -> void:
	if reb == null:
		print_debug("No rebind menu given")
		return
	_rebind_menu = reb
	if _rebind_menu.has_signal("keycode_changed"):
		_rebind_menu.keycode_changed.connect(_on_rebind_happen)
	if _rebind_menu.has_signal("on_button_pressed"):
		_rebind_menu.on_button_pressed.connect(_on_button_play_sound)
	if _rebind_menu.has_signal("on_reset_pressed"):
		_rebind_menu.on_reset_pressed.connect(_clear_rebound_values)
	_setup_rebind_settings()

func _on_audio_values_changed(master: float, music: float, sfx: float):
	#print_debug("master volume: "+ str(master))
	#print_debug("music volume: "+ str(music))
	#print_debug("sfx volume: "+ str(sfx))
	if not _game_stats.has(SOUND_TEXT):
		_game_stats[SOUND_TEXT] = {}
	_game_stats[SOUND_TEXT][MASTER_TEXT] = master
	_game_stats[SOUND_TEXT][MUSIC_TEXT] = music
	_game_stats[SOUND_TEXT][SFX_TEXT] = sfx
	_cloud_save_data()
	
func _on_rebind_happen(action_to_remap : String, event_text: String) -> void:
	print_debug("Rebind happened with: " + str(action_to_remap) + " " + str(event_text))
	if not _game_stats.has("rebinds"):
		_game_stats["rebinds"] = {}
	_game_stats["rebinds"][action_to_remap] = event_text
	_cloud_save_data()

func _on_rebind_button_pressed() -> void:
	play_button_sound.emit()
	if _rebind_menu != null:
		_rebind_menu.show()

func _clear_rebound_values() -> void:
	if _game_stats.has("rebinds"):
		_game_stats["rebinds"] = {}
		_cloud_save_data()
	else:
		print_debug("No rebound values found")

func _on_locale_options_item_selected(index: int) -> void:
	if not _game_stats.has(LANGUAGE_TEXT):
		_game_stats[LANGUAGE_TEXT] = {}
	match index:
		0:
			_game_stats[LANGUAGE_TEXT] = ENGLISH_LOC
		1:
			_game_stats[LANGUAGE_TEXT] = GREEK_LOC
	save_data()
	_setup_locale()
