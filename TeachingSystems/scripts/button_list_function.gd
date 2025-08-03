extends Control

var _items_list: Array[Control]
var _text_list: Array[String]
var _current_item: int = 0
var _current_item_type: String
var _voices
var _voice_id
var _type_array: Array[String] = ["Button", "Label", "LineEdit", "OptionButton","Slider"]
var _no_input: bool = false
var save_path = "user://SavedData.save"
var _game_stats : Dictionary = {}
var _enabledTTS: bool = false

@export
var scn_list: Array[Control]
@export
var change_foucus_sound: AudioStreamPlayer2D
@export
var wait_timer: Timer

func _ready() -> void:
	for scn in scn_list:
		if scn.has_signal("send_scene_for_signals"):
			scn.send_scene_for_signals.connect(check_and_add_signal)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	load_data()
	_voices = DisplayServer.tts_get_voices_for_language("en")
	#_voices = DisplayServer.tts_get_voices_for_language("el")
	_voice_id = _voices[1]

func _process(_delta):
	#print_debug(direction)
	if _items_list.is_empty() or _no_input:
		return
	#_items_list[_current_item].release_focus()
	if _current_item_type == "Button" or _current_item_type == "OptionButton":
		if Input.is_action_just_pressed("Down") :
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()
			_change_current_number(1)
			_check_visibility(1)
			_check_disability(1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Up") :
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()
			_change_current_number(-1)
			_check_visibility(-1)
			_check_disability(-1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right"):
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()
		if Input.is_action_just_pressed("Enter") and _items_list[_current_item].has_signal("pressed"):
			_items_list[_current_item].release_focus()
			_items_list[_current_item].pressed.emit()
	elif _current_item_type == "Label":
		if Input.is_action_just_pressed("Down") :
			_change_current_number(1)
			_check_visibility(1)
			_check_disability(1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Up") :
			_change_current_number(-1)
			_check_visibility(-1)
			_check_disability(-1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right"):
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()
	elif _current_item_type == "Slider":
		if Input.is_action_just_pressed("Down") :
			_change_current_number(1)
			_check_visibility(1)
			_check_disability(1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Up") :
			_change_current_number(-1)
			_check_visibility(-1)
			_check_disability(-1)
			_change_current_item(true)
	else:
		if Input.is_action_just_pressed("Down") :
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()
			_change_current_number(1)
			_check_visibility(1)
			_check_disability(1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Up") :
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()
			_change_current_number(-1)
			_check_visibility(-1)
			_check_disability(-1)
			_change_current_item(true)
		elif Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right"):
			_items_list[_current_item].grab_focus()
			_items_list[_current_item].release_focus()

func _recieve_items(collection = null, text = null, announcement = null) -> void:
	_items_list.clear()
	_text_list.clear()
	
	if wait_timer != null:
		_no_input = true
		wait_timer.start()
	
	if announcement != null:
		_call_announcement_only(announcement)
	if collection == null or text == null or collection == [] or text == []:
		return
	_items_list.append_array(collection)
	_text_list.append_array(text)
	_current_item = 0
	_check_visibility(1)
	_check_disability(1)
	print_debug("Receiving items")
	#for item in collection:
	#	print_debug(str(item))
	#	print_debug(_check_control_type(item))
	
	_change_current_item()
	#if _items_list[0].has_signal("pressed"):
	#	_items_list[0].pressed.emit()

func _add_items_to_list(collection: Array[Control], text: Array[String]):
	_items_list.append_array(collection)
	_text_list.append_array(text)

func _call_announcement_only(announcement: String):
	#print_debug("Called announcement")
	#print_debug(announcement)
	DisplayServer.tts_speak(announcement, _voice_id, 100, 1.0, 1.0, 0, true)

func _change_current_item(interrupt: bool = false) -> void:
	_current_item_type = _check_control_type(_items_list[_current_item])
	
	_items_list[_current_item].grab_focus()
	if(interrupt):
		_play_change_focus_sound()
	#print_debug(_current_item_type)
	#print_debug(_items_list[_current_item].visible)
	if _current_item_type == "Label":
		DisplayServer.tts_speak(_text_list[_current_item], _voice_id, 100, 1.0, 1.0, 0, false)
	else:
		DisplayServer.tts_speak(_text_list[_current_item], _voice_id, 100, 1.0, 1.0, 0, interrupt)
		

func _play_change_focus_sound() -> void:
	if change_foucus_sound != null:
		change_foucus_sound.play()

func _change_current_number(number: int) -> void:
	if _current_item == 0 and number < 0:
		_current_item = _items_list.size() - 1
	elif _current_item == _items_list.size() - 1 and number > 0:
		_current_item = 0
	else:
		_current_item += number

func _check_control_type(item) -> String:
	var item_name = str(item)
	for type in _type_array:
		if item_name.contains(type):
			return type
	return "Object"
	
func _check_visibility(number: int) -> void:
	var counter = 0
	while _items_list[_current_item].visible == false:
		if counter >= _items_list.size():
			print_debug("No Visible buttons exist")
			return
		_change_current_number(number)
		counter += 1
		

func _check_disability(number: int) -> void:
	if _check_control_type(_items_list[_current_item]) == "Button" or _check_control_type(_items_list[_current_item]) == "OptionButton":
		var counter = 0
		while _items_list[_current_item].disabled == true:
			if counter >= _items_list.size():
				print_debug("No Visible buttons exist")
				return
			_change_current_number(number)
			if _check_control_type(_items_list[_current_item]) != "Button" and _check_control_type(_items_list[_current_item]) != "OptionButton":
				return
			counter += 1

func check_and_add_signal(scn) -> void:
	if not scn_list.has(scn):
		print_debug("Scene added: " + str(scn))
		scn_list.append(scn)
	if _enabledTTS == false:
		return
	if scn.has_signal("send_interactive_items"):
		if !scn.send_interactive_items.is_connected(_recieve_items):
			scn.send_interactive_items.connect(_recieve_items)
	if scn.has_signal("send_only_announcement"):
		if !scn.send_only_announcement.is_connected(_call_announcement_only):
			scn.send_only_announcement.connect(_call_announcement_only)

func give_scns_func() -> void:
	for scn in scn_list:
		check_and_add_signal(scn)

func set_enabledTTS(value: bool) -> void:
	_enabledTTS = value
	

func _on_wait_timer_timout() -> void:
	_no_input = false

func load_data() -> void:
	var file = FileAccess.open(save_path,FileAccess.READ)
	if not file:
		return
	if file == null:
		return
	if(FileAccess.file_exists(save_path) and not file.eof_reached()):
		var current_line = JSON.parse_string(file.get_line())
		if current_line:
			_game_stats = current_line
		if _game_stats.has("enableTTS"):
			if _game_stats["enableTTS"] == true:
				_enabledTTS = true
				give_scns_func()
