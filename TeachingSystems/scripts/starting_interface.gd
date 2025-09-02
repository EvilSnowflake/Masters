extends Control
## This script should be attached to the introductory scene of the game. It shows the user the
## game's title and subtitle, along with the credits and at the same time tells them that
## they can enable the text to speech capabilities of the program if needed. It lets the
## player press their left click to continue to the main menu.

const STAGE_MENU = "res://scenes/StageMenu.tscn"
const FIRST_TIME_ANN = "Hello, this is your first time using thes program, if you want to enable text to speech for users with hearing issues, please press Enter" #NOT TRANSLATED YET!!!
const CONTINUE_TEXT = "Multiplication Teaching System. A thesis project for university. Press Left click to continue. Press Enter to exit text to speech mode"
const ContinueText2 = "Αυτό είναι Ελληνικά"
const LANGUAGE_TEXT: String = "language"

#FILE SAVE ON %APPDATA%\Godot\app_userdata\TeachingSystems
## This variable contains the path to the games save data on the user's computer
var save_path = "user://SavedData.save"
## This variable should be filled with the user's game stats found on the save file
var _game_stats : Dictionary = {}
## This variable should contain the voices found on the user's computer
var _voices
## This variable should be filled with the voice that will be used to voice text
var _voice_id

## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export
var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export
var text_for_interactive_items: Array[String]
## This variable should be filled with the label notifying the user that they can move
## to the main menu with the left click
@export
var continue_label: Label
## This variable should contain the graphic used to transition between this scene and the next.
@export
var fade_rect: ColorRect
## This variable should contain the text to speech component of the scene. If the user enables
## tts then this component should be notified so that it can begin voicing any announcements.
@export
var button_list_function: Control

## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)

func _ready() -> void:
	_voices = DisplayServer.tts_get_voices_for_language("en")
	#_voices = DisplayServer.tts_get_voices_for_language("el")
	_voice_id = _voices[1]
	load_data()

# In here we check each frame if the user presess enter so that we enable tts, if they press
# left click so that we redirect them to the next scene, and to save the data after enabling or
# disabling the tts component
func _process(_delta):
	if Input.is_action_just_pressed("Enter"):
		DisplayServer.tts_speak("", _voice_id, 100, 1.0, 1.0, 0, true)
		if _game_stats.has("enableTTS"):
			if _game_stats["enableTTS"] == true:
				_game_stats["enableTTS"] = false
			else:
				_game_stats["enableTTS"] = true
		else:
			_game_stats["enableTTS"] = true
		save_data()
	var mouseClick = Input.is_action_pressed("MouseLeft")
	if(mouseClick):
		fade_rect.call("trans",self)

## This function should be called when we want to redirect the user to the main menu.
## it pauses any sentece the tts component was voicing along with anything this script
## was saying after which it changes the current scene to the stage menu.
func change_scene() -> void:
	send_interactive_items.emit([],[],"")
	DisplayServer.tts_speak("", _voice_id, 100, 1.0, 1.0, 0, true)
	get_tree().change_scene_to_file(STAGE_MENU)

## This function should used if we want to save the user's data after a modification. It converts
## any data to a json and then writes the json to the path specified as save file.
func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var jstr = JSON.stringify(_game_stats)
	file.store_line(jstr)
	print_debug(_game_stats)
	print_debug("SAVED!")
	if button_list_function.has_method("give_scns_func") and button_list_function.has_method("set_enabledTTS"):
		button_list_function.set_enabledTTS(true)
		button_list_function.give_scns_func()
	if _game_stats["enableTTS"] == true:
		send_interactive_items.emit(interactive_items_collection,text_for_interactive_items)

## This function should be used when we want to read any saved data on the user's computer.
## If no file is found, or the file is blank then we ask the user if they want to enable tts
## if the file exists and the tts is enabled we send an announcement for the tts to voice
## otherwise we say nothing since the user has already disabled the tts.
func load_data() -> void:
	var file = FileAccess.open(save_path,FileAccess.READ)
	if not file:
		print_debug("No File")
		DisplayServer.tts_speak(FIRST_TIME_ANN, _voice_id, 100, 1.0, 1.0, 0, true)
		return
	if file == null:
		print_debug("File Empty")
		DisplayServer.tts_speak(FIRST_TIME_ANN, _voice_id, 100, 1.0, 1.0, 0, true)
		return
	if(FileAccess.file_exists(save_path) and not file.eof_reached()):
		print_debug("Found Stats")
		var current_line = JSON.parse_string(file.get_line())
		if current_line:
			_game_stats = current_line
		print_debug(_game_stats)
		_setup_locale()
		if _game_stats.has("enableTTS"):
			if _game_stats["enableTTS"] == true:
				
				send_interactive_items.emit(interactive_items_collection,text_for_interactive_items)
		else:
			DisplayServer.tts_speak(FIRST_TIME_ANN, _voice_id, 100, 1.0, 1.0, 0, true)
		#_stages_en = file.get_var()
		#Now if game stats exists we check if its empty and if it is we should
		#ask if the user has trouble hearing
		#If thbey press enter we continue with the voice
		#If it is not empty we check if the setting exists and if it says true
		#we continue with the voice
		
	else:
		print_debug("NO SAVED DATA FOUND!")
		send_interactive_items.emit([],[],FIRST_TIME_ANN)

## This function should be called when we find the user has selected a locale on the saved data.
## It takes the user's choice and changed the locale in the program.
func _setup_locale() -> void:
	if not _game_stats.has(LANGUAGE_TEXT):
		print_debug("No saved locale option")
	else:
		TranslationServer.set_locale(_game_stats[LANGUAGE_TEXT])
