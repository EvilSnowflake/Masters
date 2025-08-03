extends Control

const STAGE_MENU = "res://scenes/StageMenu.tscn"
const FIRST_TIME_ANN = "Hello, this is your first time using thes program, if you want to enable text to speech for users with hearing issues, please press Enter" #NOT TRANSLATED YET!!!
const CONTINUE_TEXT = "Multiplication Teaching System. A thesis project for university. Press Left click to continue. Press Enter to exit text to speech mode"
const ContinueText2 = "Αυτό είναι Ελληνικά"
const LANGUAGE_TEXT: String = "language"

var save_path = "user://SavedData.save"
var _game_stats : Dictionary = {}
var _voices
var _voice_id

@export
var interactive_items_collection: Array[Control]
@export
var text_for_interactive_items: Array[String]
@export
var continue_label: Label
@export
var fade_rect: ColorRect
@export
var button_list_function: Control

signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)

func _ready() -> void:
	_voices = DisplayServer.tts_get_voices_for_language("en")
	#_voices = DisplayServer.tts_get_voices_for_language("el")
	_voice_id = _voices[1]
	#if continue_label != null:
	#	interactive_items_collection = [continue_label]
	#	text_for_interactive_items = [CONTINUE_TEXT]
	load_data()

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

func change_scene() -> void:
	send_interactive_items.emit([],[],"")
	DisplayServer.tts_speak("", _voice_id, 100, 1.0, 1.0, 0, true)
	get_tree().change_scene_to_file(STAGE_MENU)

func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var jstr = JSON.stringify(_game_stats)
	file.store_line(jstr)
	print_debug(_game_stats)
	#file.store_line(jstr)
	print_debug("SAVED!")
	if button_list_function.has_method("give_scns_func") and button_list_function.has_method("set_enabledTTS"):
		button_list_function.set_enabledTTS(true)
		button_list_function.give_scns_func()
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items)

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

func _setup_locale() -> void:
	if not _game_stats.has(LANGUAGE_TEXT):
		print_debug("No saved locale option")
	else:
		TranslationServer.set_locale(_game_stats[LANGUAGE_TEXT])
