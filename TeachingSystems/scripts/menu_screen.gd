extends Control

const REGISTERSCENE = "res://addons/silent_wolf/Auth/Register.tscn"
const LOGINSCENE = "res://addons/silent_wolf/Auth/Login.tscn"

var stage_menu
var save_path = "user://SavedData.save"
#FILE SAVE ON %APPDATA%\Godot\app_userdata\TeachingSystems

@export var stage_buttons: Array[Button] = []
@export var stages_enabled = 1
@export var _codes: Array[String] = ["12345678910","2468101214161820","36912151821242730","481216202428323640","5101520253035404550","6121824303642485460","7142128354249566370","8162432404856647280","9182736455463728190","102030405060708090100"]
@export var _stages_en: Array = [1,0,0,0,0,0,0,0,0,0]

@onready var _register_button =  $MarginContainer/HBoxContainer/TitleItems/Register
@onready var _login_button = $MarginContainer/HBoxContainer/TitleItems/Login
@onready var controls = %Controls
@onready var code_input = %Code_Input
@onready var login_state_label = $MarginContainer/HBoxContainer/TitleItems/PlayerLoginLabel

func _ready():
	
	stage_menu = get_tree().get_root().get_node("Stage_Menu")
	for button in stage_buttons:
		button.pressed.connect(_on_stage_button_pressed.bind(button.text))
	_register_button.pressed.connect(_on_register_button_pressed.bind())
	_login_button.pressed.connect(_on_login_button_pressed.bind())
	load_data()
	unlock_enabled_stages()
	SilentWolf.Auth.sw_session_check_complete.connect(_on_login_complete)
	SilentWolf.Auth.auto_login_player()

func _on_stage_button_pressed(stg_num: String):
	if(stage_menu.has_method("create_game")):
		stage_menu.create_game(int(stg_num))

func enable_propedia_button(num: int):
	if(num > 9):
		print("No such stage")
		return
	print("Enabling stage "+str(num))
	_stages_en[num] = 1
	save_data()
	unlock_enabled_stages()

func _on_controls_button_pressed():
	controls.show()

func _on_exit_pressed():
	get_tree().quit()

func unlock_enabled_stages():
	for i in range(len(stage_buttons)):
		if(_stages_en[i] == 0):
			stage_buttons[i].disabled = true
		else:
			stage_buttons[i].disabled = false

func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(_stages_en)
	print("SAVED!")

func load_data():
	if(FileAccess.file_exists(save_path)):
		var file = FileAccess.open(save_path,FileAccess.READ)
		_stages_en = file.get_var()
		unlock_enabled_stages()
	else:
		print("NO SAVED DATA FOUND!")

func delete_data():
	if(FileAccess.file_exists(save_path)):
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		stages_enabled = 1
		for i in range(len(_stages_en)):
			if(i == 0):
				_stages_en[i] = 1
			else:
				_stages_en[i] =0
		file.store_var(_stages_en)
		unlock_enabled_stages()
		print("PROGRESS DELETED!")
		
func _on_clear_data_pressed():
	delete_data()

func _on_code_button_pressed():
	var code_text = code_input.text
	for i in range(len(_codes)):
		if(_codes[i] == code_text):
			enable_propedia_button(i+1)
	code_input.clear()

func _on_register_button_pressed():
	get_tree().change_scene_to_file(REGISTERSCENE)

func _on_login_button_pressed():
	get_tree().change_scene_to_file(LOGINSCENE)

func _on_login_complete(sw_result):
	update_login_state_label()
	
func update_login_state_label():
	if SilentWolf.Auth.logged_in_player:
		login_state_label.text = "Logged In"
	else:
		login_state_label.text = "NotLogged In"
