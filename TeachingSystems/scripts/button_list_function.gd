extends Control
## This script acts as a narrator fot the game. Using specific signals like send interactive items,
## send only announcements and send scene for signals any script can provide all of its buttons,
## labels, sliders, text boxes and multiple options button which the user can then navigate with 
## directional buttons. Then using the Windows voice for english the program voiced the text for
## each item for people with hearing disability. This script is disabled by default but by enabling
## it in the starting scene then all the scripts have the ability to use it. When the tts voices
## something the program slows down a bit.

## This variable contains all the Control items the current scene provides to the user
## It should be filled when the user enters the scene
var _items_list: Array[Control]
## This variable contains descriptions for the items list variable, when the user
## changes the current item then the appropriate text should be voiced
var _text_list: Array[String]
## This variable determines the index of the item the user can press in the items list, 
## can be changed with change current item
var _current_item: int = 0
## With this variable the script can determine the type of the current item,
## should be updated whenever we change the current item
var _current_item_type: String
## Variable that contains all the voices that can be used from the text to speech
var _voices
## Variable that contains the voice chsen from the voices variable
var _voice_id
## Variable containing all the types of Control Objects the program utilises.
## They are written as strings so that a simple search can determine each item.
## If anyone wants to add more types of control objects, the name of the type should be added here. 
var _type_array: Array[String] = ["Button", "Label", "LineEdit", "OptionButton",
"Slider"]
## Variable determining if the script should read user input. If its true then input stops.
var _no_input: bool = false
## Variable that points to the save data file in the users computer
var save_path = "user://SavedData.save"
## Variable that contains the game stats from the save data.
var _game_stats : Dictionary = {}
## Variable that determines if the game should use text to speech. False by default but if the user
## enables it or has it enabled from a previous session then this script can function properly.
var _enabledTTS: bool = false

## Variable that contains all the objects that can send the appropriate signals used by this script.
@export
var scn_list: Array[Control]
## Variable containing the audio that should be played when the user changes the current item
@export
var change_foucus_sound: AudioStreamPlayer2D
## Variable that contains a simple timer that disables input for a little when called
@export
var wait_timer: Timer

## When ready, this script gives all scenes the ability to add other scenes to the list. Also
## the wait timer is given its sotp input function, we check if the user has enabled tts or not
## and after reading what voices the computer has we apply the first one. 
func _ready() -> void:
	for scn in scn_list:
		if scn.has_signal("send_scene_for_signals"):
			scn.send_scene_for_signals.connect(check_and_add_signal)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	load_data()
	_voices = DisplayServer.tts_get_voices_for_language("en")
	#_voices = DisplayServer.tts_get_voices_for_language("el")
	_voice_id = _voices[1]

## While the game runs this script checks for user input if enabled and there are items on the items
## list. Depending on the type of item we currently handle there is different behavior. Generally
## the user can move to the next or previous item and focus on it with up or down and use any 
## function the item has with Enter. The left and right buttons just reset the current focus.
## If we are on a slider though, left and right change the value of the slider and enter
## does nothing. On the occasion that the current item is a line edit up, down, left and right are
## disabled and the user can only navigate with enter on the next item. Important because the user
## can navigate with WASD and since they are characters this would hinder writting.
func _process(_delta):
	if _items_list.is_empty() or _no_input:
		return
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
	elif _current_item_type == "LineEdit":
		if Input.is_action_just_pressed("Enter"):
			_change_current_number(1)
			_check_visibility(1)
			_check_disability(1)
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

## Function used to update the item list and text list variables. Should be connected to signals
## emitted from others scripts so that when the user sees new buttons to press then those buttons
## should get sent here. At first it clears both arraysso that previous items cant be selected,
## if there is an announcement then the announcement gets voiced, then each array gets the
## appropriate items and if the first item is visible and enabled then we assign it to the
## cuurrently selected variable
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
	#print_debug("Receiving items")
	_change_current_item()

## This function can be used to add more items to them main array when necessary
func _add_items_to_list(collection: Array[Control], text: Array[String]):
	_items_list.append_array(collection)
	_text_list.append_array(text)

## This function is used to voice a single string. Usually it should be connect to other scripts
## so that when the other script wants to send only announcement, then call announcement only
## should respond.
func _call_announcement_only(announcement: String) -> void:
	DisplayServer.tts_speak(announcement, _voice_id, 100, 1.0, 1.0, 0, true)

## This function should be called when the current item selected is changed. It requires a bool
## value called interrupt which if true then the tts skips whatever line was voicing to speak
## this one, otherwise it runs on a queue. Also if it skips the previous line an audio clip
## plays to signify the change of the current item. It also checks the type of element we are 
## currently on because if its a label then there will be no interruption and if its a line edit
## item then the user should immediately be able to edit it.
func _change_current_item(interrupt: bool = false) -> void:
	_current_item_type = _check_control_type(_items_list[_current_item])
	_items_list[_current_item].grab_focus()
	if(interrupt):
		_play_change_focus_sound()
	if _current_item_type == "Label":
		DisplayServer.tts_speak(_text_list[_current_item], 
		_voice_id, 100, 1.0, 1.0, 0, false)
	else:
		DisplayServer.tts_speak(_text_list[_current_item], 
		_voice_id, 100, 1.0, 1.0, 0, interrupt)
	if _current_item_type == "LineEdit":
		_items_list[_current_item].edit()

## This function is used only to play an audio clip, primarily when the current item focused
## changes.
func _play_change_focus_sound() -> void:
	if change_foucus_sound != null:
		change_foucus_sound.play()

## This function is used to modify the index of the current item. It requires a number usually
## a +1 or -1 so that we can move to the left or right of the array. It follows a simple logic
## so that when we reach the end or start of the array then we can skip to the opposite side
## if needed.
func _change_current_number(number: int) -> void:
	if _current_item == 0 and number < 0:
		_current_item = _items_list.size() - 1
	elif _current_item == _items_list.size() - 1 and number > 0:
		_current_item = 0
	else:
		_current_item += number

## This function is used to determine what type a item has. It takes the name of the item which
## necessarily contains its type and then matches it with the type array. Whatever matches with it
## is returned to the caller, if nothing matches with it, then this returns the string Object
func _check_control_type(item) -> String:
	var item_name = str(item)
	for type in _type_array:
		if item_name.contains(type):
			return type
	return "Object"

## This function is called when we change the index of the current item. It skips any items that
## are not visible so that the user cant focus on it.
func _check_visibility(number: int) -> void:
	var counter = 0
	while _items_list[_current_item].visible == false:
		if counter >= _items_list.size():
			print_debug("No Visible buttons exist")
			return
		_change_current_number(number)
		counter += 1

## This function is called when we change the index of the current item. It skips any items that
## are disabled so that the user cant focus on it.
func _check_disability(number: int) -> void:
	if (_check_control_type(_items_list[_current_item]) == "Button" or 
	_check_control_type(_items_list[_current_item]) == "OptionButton"):
		var counter = 0
		while _items_list[_current_item].disabled == true:
			if counter >= _items_list.size():
				print_debug("No Visible buttons exist")
				return
			_change_current_number(number)
			if (_check_control_type(_items_list[_current_item]) != "Button" and
			 _check_control_type(_items_list[_current_item]) != "OptionButton"):
				return
			counter += 1

## This function is called when the scene starts and should also be given to other scenes to use.
## It connects the functions: recive items, call anouncement only and check and add signal to the
## signals: send interactive items, send only announcement and send scene for signals. That way
## if the script of a scene contains any of those signals, then when they call these signals
## the appropriate function is called. That way another script can use the text to speech 
## functionality of this one.
func check_and_add_signal(scn) -> void:
	print_debug("Scene added: " + str(scn))
	if _enabledTTS == false:
		return
	if scn.has_signal("send_interactive_items"):
		if !scn.send_interactive_items.is_connected(_recieve_items):
			scn.send_interactive_items.connect(_recieve_items)
	if scn.has_signal("send_only_announcement"):
		if !scn.send_only_announcement.is_connected(_call_announcement_only):
			scn.send_only_announcement.connect(_call_announcement_only)
	if scn.has_signal("send_scene_for_signals"):
		if !scn.send_scene_for_signals.is_connected(check_and_add_signal):
			#scn.send_only_announcement.connect(_call_announcement_only)
			scn.send_scene_for_signals.connect(check_and_add_signal)

## This function is used to connect functionality to all the scenes on the array scn list by
## calling the check and add signal function
func give_scns_func() -> void:
	for scn in scn_list:
		check_and_add_signal(scn)

## This function warks as a bypass to enabling the text to speech functionality. If the application
## opens and the player hasn't enabled tts and for any reason we want to change that temporarily
## we can change it here.
func set_enabledTTS(value: bool) -> void:
	_enabledTTS = value

## This function should be connected to the wait timer after it runs out. It re-enables input
func _on_wait_timer_timout() -> void:
	_no_input = false

## This function should be called when any scene begins. It checks if there is a saved file on the
## computer and if that file contains a "enableTTS" line. If it doesnt exist or its false then the 
## text to speech functionality stops, otherwise if its true it is enabled.
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
