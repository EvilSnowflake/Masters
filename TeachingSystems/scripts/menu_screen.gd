extends Control
## This script gives function to the main menu component of the main scene. Its work includes
## creating the stages for the user to continue to the game, redirect the user to the
## register, leaderboards, and login scenes, show the user the controls menu and connect to the 
## Web API to try and receive any different numbers thourgh the web. Here the user can also change
## game's language, save their data or load it and also it houses all the audio clips that play
## during the game.

const REGISTERSCENE = "res://scenes/register_scene.tscn"
const LOGINSCENE = "res://scenes/login_screen.tscn"
const LEADERBOARDSCENE = "res://scenes/leaderboard_scene.tscn"
const STAGE_BUTTON = preload("res://scenes/stage_button.tscn")
const STAGE_BUTTON_BOX = preload("res://scenes/stage_button_box.tscn")
const HTTPS_API_URL: String = "https://localhost:7218/api/Numbers/2"
const API_URL: String = "http://localhost:5000/api/Numbers/2"
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
const ANNOUNCEMENT_TEXT: String = "Main menu, choose a stage to play or choose a button to press" #NOT TRANSLATED YET!!!


#FILE SAVE ON %APPDATA%\Godot\app_userdata\TeachingSystems
## This variable should be filled with a reference to the stage menu that houses the main
## menu, the game, the audio menu and the rebind menu
var stage_menu
## This variable contains the path to the save data for the user's computer, the user can
## find the file on %APPDATA%\Godot\app_userdata\TeachingSystems
var save_path = "user://SavedData.save"
## This variable contains the game stats of the user in a dictionary. They are added when
## we load the data from the save file and when the user finishes a stage.
var _game_stats : Dictionary = {}
## This variable should be filled with a reference to the current game object when the user
## starts a stage.
var _current_game: Object
## This variable should be filled with a reference to the audio options menu from the stage
## menu scene
var _audio_options: Control
## This variable should be filled with a reference to the audio options menu from the stage
## menu scene
var _rebind_menu: Control

## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export var text_for_interactive_items: Array[String]
## This variable determines the maximum nuber of stage buttons in each column on the scene.
@export var max_num_stage_buttons = 7
## This variable should be filled with all the stage buttons that are created for the user
## to interact with.
@export var stage_buttons: Array[Button] = []
## This variable informs the game of how many stages there should be.
@export var num_of_stages = 10
## This variable informs the game of how many waves each stage should have.
@export var num_in_propedia = 10
## This variable isn't used but contains codes for the user to unlock stages.
@export var _codes: Array[String] = ["12345678910","2468101214161820",
"36912151821242730","481216202428323640","5101520253035404550",
"6121824303642485460","7142128354249566370","8162432404856647280",
"9182736455463728190","102030405060708090100"]
## This variable should contain a reference to the statistics scene on the hierarchy
@export var statistics_scn: Control
## This variable should contain a reference to the button that is going to open
## the audio options menu
@export var audio_options_button: Button
## This variable should contain a reference to the button that is going to open
## the rebind menu
@export var rebind_button: Button
## This variable should contain a reference to the options button that will contains
## the language options for the game
@export var locale_options: OptionButton
## This variable should contain a reference to the button that is going to open
## the controls menu
@export var controls_button: Button

## This variable contains a reference to the register button
@onready var _register_button =  $MarginContainer/HBoxContainer/TitleItems/HBoxContainer2/Register
## This variable contains a reference to the login button
@onready var _login_button = $MarginContainer/HBoxContainer/TitleItems/HBoxContainer2/Login
## This variable contains a reference to the controls menu
@onready var controls = %Controls
## This variable contains a reference to the code text box, not currently used
@onready var code_input = %Code_Input
## This variable contains a reference to the login state label
@onready var login_state_label = $MarginContainer/HBoxContainer/TitleItems/PlayerLoginLabel
## This variable contains a reference to the logout button
@onready var _logout_button = $MarginContainer/HBoxContainer/TitleItems/Logout
## This variable contains a reference to the container that has the stage buttons
@onready var stage_box_container = $MarginContainer/HBoxContainer/MarginContainer/StageBoxContainer
## This variable contains a reference to the save data button
@onready var _save_data_button = $MarginContainer/HBoxContainer/TitleItems/HBoxContainer3/SaveData
## This variable contains a reference to the load data button
@onready var _load_data_button = $MarginContainer/HBoxContainer/TitleItems/HBoxContainer3/LoadData
## This variable contains a reference to the leaderboards button
@onready var _leaderboard_button = $MarginContainer/HBoxContainer/TitleItems/Leaderboards
## This variable contains a reference to the https request object
@onready var _number_req_https = $NumberRequests
## This variable contains a reference to the satistics button
@onready var _statistics_button = $MarginContainer/HBoxContainer/TitleItems/Statistics
## This variable contains a reference to the audio stream player for the button sound
@onready var button_sounds = %ButtonAudioPlayer
## This variable contains a reference to the no click panel
@onready var anti_click_panel = %AntiClickPanel
## This variable contains a reference to the wait timer
@onready var wait_timer = %WaitTimer
## This variable contains a reference the info label
@onready var info_label: Label = %InfoLabel
## This variable contains a reference to the audio stream player for the shoot sound
@onready var shoot_audio_player: AudioStreamPlayer2D = %ShootAudioPlayer
## This variable contains a reference to the audio stream player for the pickup sound
@onready var pickup_audio_player: AudioStreamPlayer2D = %PickupAudioPlayer
## This variable contains a reference to the audio stream player for the powered down sound
@onready var poweredown_audio_player: AudioStreamPlayer2D = %PoweredownAudioPlayer
## This variable contains a reference to the audio stream player for the powered up sound
@onready var powerup_audio_player: AudioStreamPlayer2D = %PowerupAudioPlayer
## This variable contains a reference to the audio stream player for the step sound
@onready var step_audio_player: AudioStreamPlayer2D = %StepAudioPlayer
## This variable contains a reference to the audio stream player for the user killed sound
@onready var user_killed_audio_player: AudioStreamPlayer2D = %UserKilledAudioPlayer
## This variable contains a reference to the audio stream player for the slider moved audio
@onready var slider_audio_player: AudioStreamPlayer2D = %SliderAudioPlayer

## This signal is emitted when the user presses a button. Should make a sound.
signal play_button_sound()
## This signal is emitted when we want to show the no click panel
signal show_anti_click()
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
	play_button_sound.connect(_on_button_play_sound)
	show_anti_click.connect(_on_anticlick_called)
	wait_timer.timeout.connect(_on_wait_timer_timeout)
	if(controls.has_signal("play_button_sound")):
		controls.play_button_sound.connect(_on_button_play_sound)
	controls.hidden.connect(_send_data_to_tts)
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
		locale_options.item_focused.connect(_on_locale_options_item_focused)
		locale_options.pressed.connect(_on_locale_options_button_pressed)
	load_data()
	
	#SILENTWOLF STTUFF
	SilentWolf.Auth.sw_session_check_complete.connect(_on_login_complete)
	SilentWolf.Auth.sw_login_complete.connect(_on_login_complete)
	SilentWolf.Auth.sw_logout_complete.connect(_on_logout_complete)
	SilentWolf.Auth.auto_login_player()
	info_label.text = tr(LOGGING_IN)
	#unlock_enabled_stages()
	#interactive_items_collection.append([controls_button,_statistics_button])
	#interactive_items_collection.append([info_label])

## This function should be connected to every stage button created in the scene. Firstly it
## tells the stage menu to create a game and return a reference to it, and then gets a
## reference to the game's stage question, informs the game of the two multiplication
## table numbers and connects any signals of sounds to the menu screen. It requires
## a stage number to know which stage to open.
func _on_stage_button_pressed(stg_num: String) -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	_send_data_to_tts()
	if(stage_menu.has_method("create_game")):
		send_interactive_items.emit([],[])
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
			#send_scene_for_signals.emit(stg_qst)
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
		send_scene_for_signals.emit(_current_game)
		if _current_game.has_method("setup_pauses_and_player"):
			_current_game.setup_pauses_and_player()

## This function is called after the user finishes a stage. It requires the number of the stage
## finished, the stats of the user from the stage, and whether or not the user died. If the user
## has succesfully finished the stage then we keep the score otherwise we replace it with the
## number 0 and also we check if the user has a better score than before so that we can post
## it and then we clalculate their highscore, save the data and unlock the appropriate stages.
func enable_propedia_button(num: int, end_stats : Dictionary = {}, user_died: bool = false) -> void:
	_current_game = null
	_send_data_to_tts(ANNOUNCEMENT_TEXT)
	if not user_died:
		end_stats[SCORE_TEXT] = find_the_score(end_stats)
	else:
		if not _game_stats.has(STAGE_PREFIX+str(num)):
			end_stats[SCORE_TEXT] = 0
		elif (_game_stats.has(STAGE_PREFIX+str(num)) and
		 _game_stats[STAGE_PREFIX+str(num)].has(SCORE_TEXT)):
			if _game_stats[STAGE_PREFIX+str(num)][SCORE_TEXT] > 0:
				var new_score = find_the_score(end_stats)
				if new_score < _game_stats[STAGE_PREFIX+str(num)][SCORE_TEXT]:
					return
				else:
					end_stats[SCORE_TEXT] = new_score
		elif (_game_stats.has(STAGE_PREFIX+str(num)) and not
		 _game_stats[STAGE_PREFIX+str(num)].has(SCORE_TEXT)):
			end_stats[SCORE_TEXT] = 0
	_game_stats[STAGE_PREFIX+str(num)] = end_stats
	_game_stats[HIGHSCORE_TEXT] = _calc_highscore()
	_cloud_save_data()
	unlock_enabled_stages()

## This function is connected to the controls button and shows the control menu while passing
## the appropriate numbers to it.
func _on_controls_button_pressed() -> void:
	play_button_sound.emit()
	if controls.has_method("show_controls_menu"):
		controls.show_controls_menu(num_in_propedia,num_of_stages)

## This function is conencted to the exit button, it quits the game after doing the necessary
## actions.
func _on_exit_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().quit()

## This function should be called when the user exits from a stage or when the game starts.
## Here we enable the stages that the user has finished and the one after those. We always
## enable the first stage, then if there is saved score from another stage we enable that
## too unless the score is 0. Also we disable any stage buttons that are outside of those
## terms.
func unlock_enabled_stages() -> void:
	for i in range(num_of_stages):
		if i == 0:
			stage_buttons[i].disabled = false
			stage_buttons[i].focus_mode = Control.FOCUS_ALL
			continue
		if not _game_stats.has(STAGE_PREFIX+str(i)):
			stage_buttons[i].disabled = true
			stage_buttons[i].focus_mode = Control.FOCUS_NONE
			continue
		if not _game_stats[STAGE_PREFIX+str(i)].has(SCORE_TEXT):
			stage_buttons[i].disabled = true
			stage_buttons[i].focus_mode = Control.FOCUS_NONE
			continue
		if _game_stats[STAGE_PREFIX+str(i)][SCORE_TEXT] <= 0:
			stage_buttons[i].disabled = true
			stage_buttons[i].focus_mode = Control.FOCUS_NONE
			continue
		stage_buttons[i].disabled = false
		stage_buttons[i].focus_mode = Control.FOCUS_ALL

## This function should be called when we want to locally write any progress of the
## user to a file on their computer. It uses file access to open a file, or create it
## if it doesn't exist and then makes the stats into a JSON that we then write to
## the file.
func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var jstr = JSON.stringify(_game_stats)
	file.store_line(jstr)
	print_debug(_game_stats)
	print_debug("SAVED!")

## This function should be called when we want to read any data saved on the computer.
## Firstly we read the file and if it doesn't exist, or is empty we do nothing, otherwise
## we read the data as a JSON and then move the data to a variable, and then setup specific
## components in the game that can be saved, like audio options, rebindings, languages and tts.
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
		_check_text_to_speech_flag()
	else:
		print_debug("NO SAVED DATA FOUND!")

## This function should be called when we want to clear the user's data from their computer.
## If the file exists then we clear the variable of game data in the program, then save that
## clear data on the file and on cloud after which we lock the appropriate stages.
func delete_data() -> void:
	if(FileAccess.file_exists(save_path)):
		_game_stats = {}
		save_data()
		_cloud_save_data()
		unlock_enabled_stages()
		print_debug("PROGRESS DELETED!")

## This function is connected to the clear data button. It deletes any local game data and on the
## cloud.
func _on_clear_data_pressed() -> void:
	play_button_sound.emit()
	delete_data()

## This function is connected to the code button. The code button is not currently used but
## if the user inputs a specific set of numbers on the text box end presses the code button
## then the appropriate stage unlocks.
func _on_code_button_pressed() -> void:
	var code_text = code_input.text
	for i in range(len(_codes)):
		if(_codes[i] == code_text):
			enable_propedia_button(i+1)
	code_input.clear()

## This function should be connected to the sign up button. It redirects the user to the
## register scene
func _on_register_button_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(REGISTERSCENE)

## This function should be connected to the login button. It redirects the user to the login scene
func _on_login_button_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(LOGINSCENE)

## This function should be called when the user succesfully logins. It should be called after
## the user is redirected from the login scene. It aims to update the login status of the user
## and also show the appropriate buttons
func _on_login_complete(_sw_result) -> void:
	info_label.text = ""
	update_login_state_label()

## This function should be connected to the logout button. It notifies silent wolf that the player
## wants to log out.
func _on_logout_button_pressed() -> void:
	play_button_sound.emit()
	SilentWolf.Auth.logout_player()

## This function should be called when silent wolf successfully logs the player out by updating
## the login status and hiding the appropriate buttons 
func _on_logout_complete(_a,_b) -> void:
	_send_data_to_tts("Logged out")
	update_login_state_label()

## This function should be connected to the leaderboard button. It redirects the user the
## leaderboards scene.
func _on_leader_button_pressed() -> void:
	play_button_sound.emit()
	show_anti_click.emit()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(LEADERBOARDSCENE)

## This function should be called whenever we want to update the user's login status.
## It attempts to take the username of the player if they are logged in and then either
## shows the name on the login status while showing the buttons: login, logout, save, load,
## leaderboard and hiding the login button. Otherwise it just says not logged in and hides
## the buttons.
func update_login_state_label() -> void:
	if SilentWolf.Auth.logged_in_player:
		var username = SilentWolf.Auth.logged_in_player
		login_state_label.text = tr(LOGGED_IN_AS) + " " + username
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
	#Check if there are other signals connected and disconnect them
	if login_state_label.focus_entered.is_connected(_on_label_focused):
		login_state_label.disconnect("focus_entered",_on_label_focused)
	login_state_label.focus_entered.connect(_on_label_focused.bind(tr(login_state_label.text)))

## This function should be called when we want to add a stage button to the scene. It instantiates
## a stage box into which the stage buttons will be inserted, which it inserts on the stage
## box container. Then depending on the first number inputed it creates a new stage button
## which it inserts on the stage box and then adds to the stage buttons. Then adds a counter
## to the button number and does the whole operation again until it reaches the desired
## number. Then returns the button number counter to the caller so that they know how many
## stages are made.
func _add_stage_and_button(number: int, button_num: int) -> int:
	var stage_box = STAGE_BUTTON_BOX.instantiate()
	stage_box_container.add_child(stage_box)
	for i in range(number):
		var stage : Button = STAGE_BUTTON.instantiate()
		stage.text = str(button_num+1)
		stage_box.add_child(stage)
		stage_buttons.append(stage)
		button_num += 1
	return button_num

## This function should be called when the users answers a question given to them during
## gameplay. It requires the numbers on the question and if it was correct or not.
## Then if its not already on the game stats it adds the user's answer in the dictionary
func _update_answrs(numbers: String, result: bool) -> void:
	if not _game_stats.has(ANSWERS_TEXT):
		_game_stats[ANSWERS_TEXT] = {}
	_game_stats[ANSWERS_TEXT][numbers] = result

## This function should be connected to the cloud load data button. It attempts to receive data
## from Silent Wolf in regards to the user.
func _on_cloud_load_button_pressed() -> void:
	play_button_sound.emit()
	_cloud_load_data()

## This function should be called in order to get the data saved to the Silent Wolf backend
## from the user. It attempts to get the requires results from Silent Wolf asynchronously
## and if it is succesfull, it merges the local data with the result and then saves the data
## localy and on the cloud, after which it unlocks the appropriate stages, sets up the rebind
## menu, the audio settings and the language chosen. Otherwise it does nothing.
func _cloud_load_data() -> void:
	if SilentWolf.Auth.logged_in_player:
		print_debug("Loading data from cloud")
		info_label.text = tr(LOADING_DATA)
		
		#load data async
		var sw_result = await SilentWolf.Players.get_player_data(
			SilentWolf.Auth.logged_in_player).sw_get_player_data_complete
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

## This function should be connected with the save data to cloud button. It attempts to send
## the local data to the silentwolf backend service.
func _on_cloud_save_data_pressed() -> void:
	play_button_sound.emit()
	_cloud_save_data()

## This function should be called when we want to upload the user's local data to the cloud. Firstly
## it saves the users data localy, then check if the user is logged in and saves the data to the
## logged in user's account. If the save is successful then we also upload the users highscore,
## otherwise nothing happens.
func _cloud_save_data() -> void:
	save_data()
	if SilentWolf.Auth.logged_in_player:
		info_label.text = tr(SAVING_DATA)
		print_debug("Saving to cloud")
		var sw_result = await SilentWolf.Players.save_player_data(
			SilentWolf.Auth.logged_in_player,
			 _game_stats).sw_save_player_data_complete
		if(sw_result and sw_result.success):
			print_debug("Saved to cloud")
			upload_lead_score()
		else:
			print_debug("Save failed")
		info_label.text = ""

## This function should be used when we want to calculate the users total score for a specific
## stage. It requires the user's game stats for the stage and with that it uses a specific
## calculation to then return the score. The calculation is: base score + correct answers * points
## for correct answers - wrong answers * points for wrong answers + level * points for each level.
## Then if the user finishes the stage at a good time we reward them accordingly.
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
	score = (base_score + (total_corr*points_for_answ) -
	 (total_wrng*points_for_wrng_answ) + (points_for_lvl*total_lvl))
	if total_t < expctd:
		score += expctd-total_t
	return score

## This function should be used if we want to send the user's high score to the silentwolf
## leaderboards. The game needs to already have a highscore and the user should be logged in.
## After that it tries to receive a previous highscore of the user and if it receives one
## and its bigger or equal to the current highscore then it doesn't upload anything. Otherwise
## it attempts to send the current highscore to the silent wolf backend.
func upload_lead_score():
	if not _game_stats.has(HIGHSCORE_TEXT) or not SilentWolf.Auth.logged_in_player:
		return
	var sw_result = await SilentWolf.Scores.get_top_score_by_player(
		SilentWolf.Auth.logged_in_player).sw_top_player_score_complete
	print_debug(sw_result)
	if sw_result == null:
		return
	print_debug(sw_result["top_score"][SCORE_TEXT])
	print_debug(_game_stats[HIGHSCORE_TEXT])
	if sw_result["top_score"][SCORE_TEXT] >= _game_stats[HIGHSCORE_TEXT]:
		print_debug("Highscore has not changed or improved")
		return
	info_label.text = tr(SAVING_HIGHSCORE)
	var sw_score_result: Dictionary = await SilentWolf.Scores.save_score(
		SilentWolf.Auth.logged_in_player, _game_stats[HIGHSCORE_TEXT]).sw_save_score_complete
	info_label.text = ""
	print_debug("Score persisted successfully: " + str(sw_score_result.score_id))

## This function should be used if we want to find out the user's highscore. It adds
## all the instances of score in the current user's game stats which it then returns as a result.
func _calc_highscore() -> int:
	var score: int = 0
	for stat : String in _game_stats:
		if stat.begins_with("stage"):
			if _game_stats[stat].has(SCORE_TEXT):
				score += _game_stats[stat][SCORE_TEXT]
	return score

## This function should be called by the HTTP Request component. After making the request
## it reads the result and the returned HTTP body from which it takes out the two numbers
## given but the Web API and then updates the number of stages and number of waves. It then
## tryies to setup the stage buttons so that they are added correctly.
func _on_request_completed(result,_response_code,_headers,body) -> void:
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print_debug("Data found from the api")
		num_of_stages = int(json["numberOne"])
		num_in_propedia = int(json["numberTwo"])
		setupButtons()
	else:
		setupButtons()

## This function attempts to add all the stage buttons for the user to be able to play.
## It checks if there are buttons already present so that no more buttons are added. Then
## makes a small calculation to divide the amount of button that will be added with the
## number of rows given. Then it uses that result to add the stage buttons after which
## it gathers and sends the to the tts component to be voiced to the user. In between it
## takes a reference to its parent object so that we are able to communicate with it.
func setupButtons() -> void:
	if(stage_box_container.get_child_count() > 0):
		print_debug("Buttons found, operation stopped")
		return
	var rest = int(num_of_stages)%max_num_stage_buttons
	var numOfTimes = floor(num_of_stages/max_num_stage_buttons)
	var button_num = 0
	while numOfTimes > 0:
		button_num = _add_stage_and_button(max_num_stage_buttons,button_num)
		numOfTimes -= 1
	button_num = _add_stage_and_button(rest,button_num)
	stage_menu = get_tree().get_root().get_node("Stage_Menu")
	
	#BUTTONS STUFF
	for button in stage_buttons:
		interactive_items_collection.push_front(button)
		text_for_interactive_items.push_front("Stage " + button.text)
		button.pressed.connect(_on_stage_button_pressed.bind(button.text))
	unlock_enabled_stages()
	if _game_stats.has("enableTTS"):
		if _game_stats["enableTTS"] == true:
			print_debug("Game stats have enable tts")
			_send_data_to_tts(ANNOUNCEMENT_TEXT)

## This function helps the audio options menu set up their values. If we have a reference to
## it then we initialise it's values and then load any saved data.
func _setup_audio_settings() -> void:
	if _audio_options == null:
		print_debug("No audio options provided")
		return
	if _audio_options.has_method("initialiase_values"):
		_audio_options.initialiase_values()
	if _audio_options.has_method("load_values") and _game_stats.has(SOUND_TEXT):
		_audio_options.load_values(_game_stats[SOUND_TEXT][MASTER_TEXT],
		_game_stats[SOUND_TEXT][MUSIC_TEXT],
		_game_stats[SOUND_TEXT][SFX_TEXT])

## This function helps the rebind menu set up any changes from the previous session.
func _setup_rebind_settings() -> void:
	if _rebind_menu == null:
		print_debug("No rebind menu provided")
		return
	if _game_stats.has("rebinds"):
		for rebind in _game_stats["rebinds"]:
			if _rebind_menu.has_method("change_input"):
				_rebind_menu.change_input(rebind, _game_stats["rebinds"][rebind])

## This function changes the language of the game depending on if the player has already saved
## from a previous sesison. If it exists then it changes the locale options button and
## then sets the locale of the game.
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

## This function should be connected to the statistics button. If the statistics scene exists
## It notifies it that when it is hidden we should send the main menu buttons to the tts component
## and the it sends that scene the game stats and the two numbers of the multiplication table
func _enableStatsScreen() -> void:
	play_button_sound.emit()
	if(statistics_scn == null):
		print_debug("No statistics scene found")
		return
	if !statistics_scn.hidden.is_connected(_send_data_to_tts):
		statistics_scn.hidden.connect(_send_data_to_tts)
	if statistics_scn.has_method("show_statistics_menu"):
		statistics_scn.show_statistics_menu(_game_stats,num_of_stages,num_in_propedia)

## This function should be called when a button is pressed. It plays an audio file connected
## to the button audio player
func _on_button_play_sound() -> void:
	button_sounds.play()

## This function should be called when the values on the audio slider change. It plays an audio
## file connected to the slider audio player
func _on_slider_value_changed_sound() -> void:
	slider_audio_player.play()

## This function should be called when we don't want the player to be able to click anything
## on the screen. It shows an invisible panel that overrides any clicking made.
func _on_anticlick_called() -> void:
	anti_click_panel.show()

## This function should be connected to the wait timer. After it ends counting down it hides
## the panel that stops the player from clicking.
func _on_wait_timer_timeout() -> void:
	anti_click_panel.hide()

## This function should be called when the the player makes a step. It plays an audio
## file connected to the step audio player
func _play_step_sound() -> void:
	step_audio_player.play()

## This function should be called when the players gun fires. It plays an audio
## file connected to the shoot audio player
func _play_shoot_sound() -> void:
	shoot_audio_player.play()

## This function should be called when the player picks up an item. It plays an audio
## file connected to the pickup audio player
func _play_pickup_sound() -> void:
	pickup_audio_player.play()

## This function should be called when the player levels up. It plays an audio
## file connected to the levelup audio player
func _play_levelup_sound() -> void:
	print_debug("Make levelup sound!")

## This function should be called when the player dies. It plays an audio file connected to the 
## user killed audio player
func _play_on_die_sound() -> void:
	user_killed_audio_player.play()

## This function should be called when the player receives a reward in the game. It plays an audio
## file connected to the power up or down audio player
func _play_rewarded_sound(powered: bool) -> void:
	if powered:
		powerup_audio_player.play()
	else:
		poweredown_audio_player.play()

## This function should be connected to the audio option button. It shows the audio options menu.
func _on_audio_options_button_pressed():
	send_interactive_items.emit([],[])
	play_button_sound.emit()
	if _audio_options.has_method("show_audio_menu"):
		_audio_options.show_audio_menu()

## This function should be called by other scenes so that this script has a reference to the
## audio options menu. It takes a control object as input which it the fills the audio options
## variable with. Then it helps the audio options menu connect any signals with the tts component
## so that all of its buttons can be sent to it to be voiced. Then it sets up any previous settings
## on the audio menu and then conencts any sound related signals to the appropriate functions.
func set_audio_options(opt: Control) -> void:
	if opt == null:
		print_debug("No options panel given!")
		return
	_audio_options = opt
	send_scene_for_signals.emit(_audio_options)
	audio_options_button.pressed.connect(_on_audio_options_button_pressed)
	_setup_audio_settings()
	if _audio_options.has_signal("audio_values_changed"):
		_audio_options.audio_values_changed.connect(_on_audio_values_changed)
	if _audio_options.has_signal("on_button_pressed"):
		_audio_options.on_button_pressed.connect(_on_button_play_sound)
	if _audio_options.has_signal("sliders_value_change"):
		_audio_options.sliders_value_change.connect(_on_slider_value_changed_sound)
	if !_audio_options.hidden.is_connected(_send_data_to_tts):
		_audio_options.hidden.connect(_send_data_to_tts)

## This function should be used by other scenes to give this script a reference to the rebind menu.
## It takes a control object as input which it the fills the rebind options
## variable with. Then it helps the rebind menu connect any signals with the tts component
## so that all of its buttons can be sent to it to be voiced. Then it sets up changed rebinds
## from previous sessions and then conencts any sound related signals to the appropriate functions.
func set_rebind_menu(reb: Control) -> void:
	if reb == null:
		print_debug("No rebind menu given")
		return
	_rebind_menu = reb
	send_scene_for_signals.emit(_rebind_menu)
	if _rebind_menu.has_signal("keycode_changed"):
		_rebind_menu.keycode_changed.connect(_on_rebind_happen)
	if _rebind_menu.has_signal("on_button_pressed"):
		_rebind_menu.on_button_pressed.connect(_on_button_play_sound)
	if _rebind_menu.has_signal("on_reset_pressed"):
		_rebind_menu.on_reset_pressed.connect(_clear_rebound_values)
	if !_rebind_menu.hidden.is_connected(_send_data_to_tts):
		_rebind_menu.hidden.connect(_send_data_to_tts)
	_setup_rebind_settings()

## This function should be called by the audio options menu after the user chooses to save
## the changed values. It receives the values, inputs the to the game stats variable and then saves
## the data localy and in the cloud if possible.
func _on_audio_values_changed(master: float, music: float, sfx: float):
	if not _game_stats.has(SOUND_TEXT):
		_game_stats[SOUND_TEXT] = {}
	_game_stats[SOUND_TEXT][MASTER_TEXT] = master
	_game_stats[SOUND_TEXT][MUSIC_TEXT] = music
	_game_stats[SOUND_TEXT][SFX_TEXT] = sfx
	_cloud_save_data()

## This function should be called when the user rebinds a key in the rebind menu. It adds the
## action and the key to the game stats variable and then saves it localy and on the cloud
## if possible.
func _on_rebind_happen(action_to_remap : String, event_text: String) -> void:
	if not _game_stats.has("rebinds"):
		_game_stats["rebinds"] = {}
	_game_stats["rebinds"][action_to_remap] = event_text
	_cloud_save_data()

## This function should be connected to the rebind button. It shows the rebind menu.
func _on_rebind_button_pressed() -> void:
	play_button_sound.emit()
	if _rebind_menu != null:
		if _rebind_menu.has_method("show_rebind_menu"):
			_rebind_menu.show_rebind_menu()

## This function deletes any changed key codes on the game stats. It should be called by the
## rebind menu to clear any saved data by the user.
func _clear_rebound_values() -> void:
	if _game_stats.has("rebinds"):
		_game_stats["rebinds"] = {}
		_cloud_save_data()
	else:
		print_debug("No rebound values found")

## This function should be connected to the language options button. After the user presses the
## button to see the language options we should send a voiced message to the user through the tts
## component for them to be informed of what they pressed.
func _on_locale_options_button_pressed() -> void:
	send_interactive_items.emit([],[],"Select a language from the given options")

## This function should be connected to the language options button. When the user focuses
## on a specific option it sends the item's content to the tts component for the text to be
## voiced
func _on_locale_options_item_focused(index: int) -> void:
	var item_text = locale_options.get_item_text(index)
	send_only_announcement.emit(tr(item_text))

## This function should be connected to the language options button. When the user selects
## one of the options depending on the index selected it changes the saved language option
## on the game stats, saves the data and then changes the language of the game.
func _on_locale_options_item_selected(index: int) -> void:
	var item_text = locale_options.get_item_text(index)
	print_debug(interactive_items_collection)
	print_debug(text_for_interactive_items)
	_send_data_to_tts("You have chosen " + tr(item_text))
	if not _game_stats.has(LANGUAGE_TEXT):
		_game_stats[LANGUAGE_TEXT] = {}
	match index:
		0:
			_game_stats[LANGUAGE_TEXT] = ENGLISH_LOC
		1:
			_game_stats[LANGUAGE_TEXT] = GREEK_LOC
	save_data()
	_setup_locale()

## This function should be used when we wants to check if the user has enabled the text to speech
## option in the saved data.
func _check_text_to_speech_flag():
	if _game_stats == {}:
		print_debug("Game stats empty")
		_game_stats["enableTTS"] = false
		return
	if not _game_stats.has("enableTTS"):
		print_debug("Game stats dont have enable tts")
		_game_stats["enableTTS"] = false
		return

## This function should be connected to every label that we want to the user to be abe to read
## through the tts component. When it is focused, the label sends it's text to the tts component
## which then voices the text.
func _on_label_focused(labeltext: String):
	send_only_announcement.emit(labeltext)

## This function should be called when the users enters the main menu, or when other menus
## disappear. It sends all the appropriate menu buttons to the tts component for them to be
## voiced and also an announcement if there is one inputed.
func _send_data_to_tts(announcement = null) -> void:
	if _current_game == null:
		send_interactive_items.emit(interactive_items_collection, text_for_interactive_items,announcement)
	else:
		if not _current_game.has_method("send_pauses_items_to_buttons_func"):
			return
		_current_game.send_pauses_items_to_buttons_func()
