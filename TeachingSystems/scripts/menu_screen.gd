extends Control

const REGISTERSCENE = "res://scenes/register_scene.tscn"
const LOGINSCENE = "res://scenes/login_screen.tscn"
const LEADERBOARDSCENE = "res://scenes/leaderboard_scene.tscn"
const STAGE_BUTTON = preload("res://scenes/stage_button.tscn")
const STAGE_BUTTON_BOX = preload("res://scenes/stage_button_box.tscn")
const HTTPS_API_URL = "https://localhost:7218/api/Numbers/2"
const API_URL = "http://localhost:5000/api/Numbers/1"
#FILE SAVE ON %APPDATA%\Godot\app_userdata\TeachingSystems
var stage_menu
var save_path = "user://SavedData.save"
var _game_stats : Dictionary = {}
var _current_game

@export var max_num_stage_buttons = 7
@export var stage_buttons: Array[Button] = []
@export var num_of_stages = 10
@export var num_in_propedia = 10
@export var _codes: Array[String] = ["12345678910","2468101214161820","36912151821242730","481216202428323640","5101520253035404550","6121824303642485460","7142128354249566370","8162432404856647280","9182736455463728190","102030405060708090100"]

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


func _ready():
	#API STUFF
	_number_req_https.request_completed.connect(_on_request_completed)
	_number_req_https.request(API_URL)
	
	_register_button.pressed.connect(_on_register_button_pressed.bind())
	_login_button.pressed.connect(_on_login_button_pressed.bind())
	_logout_button.pressed.connect(_on_logout_button_pressed)
	_save_data_button.pressed.connect(_cloud_save_data)
	_load_data_button.pressed.connect(_cloud_load_data)
	_leaderboard_button.pressed.connect(_on_leader_button_pressed)
	load_data()
	#_game_stats["highscore"] = _calc_highscore()
	
	#SILENTWOLF STTUFF
	SilentWolf.Auth.sw_session_check_complete.connect(_on_login_complete)
	SilentWolf.Auth.sw_login_complete.connect(_on_login_complete)
	SilentWolf.Auth.sw_logout_complete.connect(_on_logout_complete)
	SilentWolf.Auth.auto_login_player()
	#unlock_enabled_stages()
	


func _on_stage_button_pressed(stg_num: String) -> void:
	if(stage_menu.has_method("create_game")):
		_current_game = stage_menu.create_game(int(stg_num),num_in_propedia)
		if _current_game.has_method("get_stage_quest"):
			var stg_qst = _current_game.get_stage_quest()
			if stg_qst.has_signal("answer_given"):
				stg_qst.answer_given.connect(_update_answrs)
				#stg_qst.correct_answer.connect(_update_answrs)
				#print(stg_qst.answer_given.get_connections())
			if ("menu_screen_node" in stg_qst):
				stg_qst.menu_screen_node = self
			if ("max_num" in stg_qst):
				stg_qst.max_num = num_of_stages
			if ("num_in_propedia" in stg_qst):
				stg_qst.num_in_propedia = num_in_propedia

func enable_propedia_button(num: int, end_stats : Dictionary = {}, user_died: bool = false) -> void:
	#print("Enabling stage "+str(num))
	if(not user_died):
		_game_stats["stage_"+str(num)] = end_stats
		_game_stats["highscore"] = _calc_highscore()
	#_stages_en[num] = 1
	_cloud_save_data()
	unlock_enabled_stages()

func _on_controls_button_pressed() -> void:
	controls.show()

func _on_exit_pressed() -> void:
	get_tree().quit()

func unlock_enabled_stages() -> void:
	for i in range(num_of_stages):
		if _game_stats.has("stage_"+str(i)) or i == 0:
			stage_buttons[i].disabled = false
		else:
			stage_buttons[i].disabled = true
		#if _game_stats.has("stage_"+str(i)):
		#	stage_buttons[i+1].disabled = false

func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var jstr = JSON.stringify(_game_stats)
	file.store_line(jstr)
	print(_game_stats)
	#file.store_line(jstr)
	print("SAVED!")

func load_data() -> void:
	
	var file = FileAccess.open(save_path,FileAccess.READ)
	if not file:
		print("No File")
		return
	if file == null:
		print("File Empty")
		return
	if(FileAccess.file_exists(save_path) and not file.eof_reached()):
		print("Found Stats")
		var current_line = JSON.parse_string(file.get_line())
		if current_line:
			_game_stats = current_line
		print(_game_stats)
		#_stages_en = file.get_var()
		
	else:
		print("NO SAVED DATA FOUND!")

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
		print("PROGRESS DELETED!")
		
func _on_clear_data_pressed() -> void:
	delete_data()

func _on_code_button_pressed() -> void:
	var code_text = code_input.text
	for i in range(len(_codes)):
		if(_codes[i] == code_text):
			enable_propedia_button(i+1)
	code_input.clear()

func _on_register_button_pressed() -> void:
	get_tree().change_scene_to_file(REGISTERSCENE)

func _on_login_button_pressed() -> void:
	get_tree().change_scene_to_file(LOGINSCENE)

func _on_login_complete(sw_result) -> void:
	update_login_state_label()

func _on_logout_button_pressed() -> void:
	SilentWolf.Auth.logout_player()

func _on_logout_complete(a,b) -> void:
	update_login_state_label()

func _on_leader_button_pressed() -> void:
	get_tree().change_scene_to_file(LEADERBOARDSCENE)

func update_login_state_label() -> void:
	if SilentWolf.Auth.logged_in_player:
		var username = SilentWolf.Auth.logged_in_player
		login_state_label.text = "LOGGED IN AS " + username
		_cloud_load_data()
		_logout_button.show()
		_save_data_button.show()
		_load_data_button.show()
		_leaderboard_button.show()
		_login_button.hide()
	else:
		login_state_label.text = "NOT LOGGED IN"
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
	if not _game_stats.has("answers"):
		_game_stats["answers"] = {}
	_game_stats["answers"][numbers] = result

func _cloud_load_data() -> void:
	if SilentWolf.Auth.logged_in_player:
		print("Loading data from cloud")
		
		#load data async
		var sw_result = await SilentWolf.Players.get_player_data(SilentWolf.Auth.logged_in_player).sw_get_player_data_complete
		print("Player data from cloud: " + str(sw_result.player_data))
		
		#show results
		if sw_result and sw_result.success and sw_result.player_data:
			_game_stats.merge(sw_result.player_data)
			save_data()
			_cloud_save_data()
			unlock_enabled_stages()
			print("Found data on cloud")
		else:
			print("Load failed from cloud")

func _cloud_save_data():
	save_data()
	if SilentWolf.Auth.logged_in_player:
		print("Saving to cloud")
		var sw_result = await SilentWolf.Players.save_player_data(SilentWolf.Auth.logged_in_player, _game_stats).sw_save_player_data_complete
		if(sw_result and sw_result.success):
			print("Saved to cloud")
			upload_lead_score()
		else:
			print("Save failed")

func find_the_score(stats: Dictionary) -> int:
	var score = 0
	if stats == {}:
		print("Empty stats")
		return score
	var total_en: int = stats["total_enemies"]
	var total_t: int = stats["total_time"]
	var total_corr: int = stats["correct_answers"]
	var total_wrng: int = stats["wrong_answers"]
	var time_for_en: int = 3
	var points_for_answ: int = 5
	var expctd: int = total_en * time_for_en
	var base_score: int = 100
	
	score = base_score + (total_corr*points_for_answ) - (total_wrng*points_for_answ)
	if total_t < expctd:
		score += expctd-total_t
	
	return score

func upload_lead_score():
	if not _game_stats.has("highscore") or not SilentWolf.Auth.logged_in_player:
		return
	var sw_result = await SilentWolf.Scores.get_top_score_by_player(SilentWolf.Auth.logged_in_player).sw_top_player_score_complete
	print(sw_result)
	if sw_result == null:
		return
	if sw_result["top_score"]["score"]== _game_stats["highscore"]:
		print("Highscore has not changed")
		return
	var sw_score_result: Dictionary = await SilentWolf.Scores.save_score(SilentWolf.Auth.logged_in_player, _game_stats["highscore"]).sw_save_score_complete
	print("Score persisted successfully: " + str(sw_score_result.score_id))

func _calc_highscore() -> int:
	var score: int = 0
	for stat : String in _game_stats:
		if stat.begins_with("stage"):
			score += find_the_score(_game_stats[stat])
	
	return score

func _on_request_completed(result,response_code,headers,body):
	print("Request result : "+str(result))
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print("Data found from the api")
		num_of_stages = int(json["numberOne"])
		num_in_propedia = int(json["numberTwo"])
		setupButtons()
	else:
		setupButtons()
	
func setupButtons():
	print("setting up buttons")
	if(stage_box_container.get_child_count() > 0):
		print("Buttons found, operation stopped")
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
