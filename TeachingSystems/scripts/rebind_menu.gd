extends Control
## This script should be attached to the rebind menu scene. Here the user can change any 
## keycodes related to the game that we have chosen from the input map. After cicking one of the
## created buttons dedicated to changing the appropriate action and pressing a button then
## that button is set for this session. After saving the change the modification is set
## on the game stats for future sessions. The user can also change any modification to the default
## values.

const PRESS_KEY: String = "PRESSKEY_TEXT"
const ANNOUNCEMENT = "Rebind keys menu. Here you can change the keycodes for each action in the game to another key from the keyboard."
const INPUT_ACTIONS = {
	"Up": "UP",
	"Down": "DOWN",
	"Left": "LEFT",
	"Right": "RIGHT",
	"Escape": "PAUSE"
	#"Enter": "ENTER"
}

## This variable determines if the user is currently changing their button's keycodes
var _is_remapping: bool = false
## This variable determines the action that is currently being changed
var _action_to_remap: String = ""
## This variable determines the button the will be used for the remapping
var _remapping_button: Button = null

## This variable contains a preloaded scene for the button that allows the user to change
## an action
@onready var input_button_scene = preload("res://scenes/input_button.tscn")

## This variable should point to the list that will contain all the buttons
## for the user to change the keybinds
@export var action_list: VBoxContainer
## This variable should point to the reset button
@export var reset_button: Button
## This variable should point to the exit button
@export var exit_button: Button
## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export var text_for_interactive_items: Array[String]

## This signal should be emitted when the user changes a keybind
signal keycode_changed(action_to_remap: String, event_text: String)
## This signal should be emitted when any button is pressed
signal on_button_pressed()
## This signal should be emitted when the user presses the reset button
signal on_reset_pressed()
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)

func _ready() -> void:
	_create_action_list()
	reset_button.pressed.connect(_on_reset_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

## This function attempts to create a button for each action we have chosen for the user
## to be able to change. Firstly it takes input map from the project settings, then if there
## is an action list it clears the list's children and then it uses the INPUT_ACTIONS constant
## to choose which of the actions its going to show. It chooses the action and keycode,
## instantiates an input button, inserts the info in the button while removing some extra
## text the user doesn't need and then adds the button to the action list while also making 
## another list that will be sent to the tts component to be voiced along with the name of the
## action. At the end it also connects the appropriate function to each button so that if the
## user presses them, the keybinding starts.
func _create_action_list() -> void:
	InputMap.load_from_project_settings()
	if action_list == null:
		print_debug("Action list is null!")
		return
	for item in action_list.get_children():
		item.queue_free()
	var temp_ar1: Array
	var temp_ar2: Array
	for action in INPUT_ACTIONS:
		var button = input_button_scene.instantiate()
		var action_label: Label = button.find_child("LabelAction")
		var input_label: Label = button.find_child("LabelInput")
		action_label.text = INPUT_ACTIONS[action]
		var events = InputMap.action_get_events(action)
		var text_for_label = ""
		if events.size() > 0:
			text_for_label = events[0].as_text().trim_suffix(" (Physical)")
		else:
			text_for_label = ""
		input_label.text = text_for_label
		action_list.add_child(button)
		temp_ar1.push_back(button)
		temp_ar2.push_back(INPUT_ACTIONS[action])
		button.pressed.connect(_on_input_button_pressed.bind(button,action))
	for t1 in temp_ar1:
		interactive_items_collection.append(t1)
	for t2 in temp_ar2:
		text_for_interactive_items.append(t2)

## This function should be connected to all input button created for rebinding. It checks if
## we are currently not doing a different remap, enables the remapping variable, and assigns
## the action and button using the input given, after which it changes the button's text to
## "press key".
func _on_input_button_pressed(button: Button, action: String) -> void:
	on_button_pressed.emit()
	if !_is_remapping:
		_is_remapping = true
		_action_to_remap = action
		_remapping_button = button
		button.find_child("LabelInput").text = tr(PRESS_KEY)

## This function is called when the user presses a key after pressing one of the action
## buttons. It requires that the script is currently in remapping mode, and then it needs
## the input event to be an Input Event Key or that it's an Input Event Mouse Button that is pressed
## and at the same time that the button is not the Enter key, because enter is used for text boxes.
## Also if the user double clicks with their mouse, the event is translated to a single click.
## With that data, it changes the input of the currently remapping action to the input event,
## it sends a signal with the event change, sends a voiced announcement with the change that
## occured, marks the input as complete and then switches to not remapping and clears
## the remapping variables.
func _input(event) -> void:
	if _is_remapping:
		if (((event is InputEventKey) || 
		(event is InputEventMouseButton && event.pressed)) && 
		event.as_text() != "Enter"):
			change_input(_action_to_remap,event.as_text())
			print_debug(" Action to remap : " + _action_to_remap + 
			" , Event : " + event.as_text() + " , Remapping Button : " + 
			str(_remapping_button))
			keycode_changed.emit(_action_to_remap, event.as_text())
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
			send_only_announcement.emit(" Action to remap : " + _action_to_remap + 
			" , Event : " + event.as_text() + " , Action for remap : " + 
			str(INPUT_ACTIONS[_action_to_remap]))
			_is_remapping = false
			_action_to_remap = ""
			_remapping_button = null
			accept_event()

## This function should be used to change a specific action in the action list buttons 
## so that the connected button matches with the button that was just remapped according
## to the variables given.
func _update_action_list(action_to_remap: String, event) -> void:
	for item: Button in action_list.get_children():
		if item.find_child("LabelAction").text == INPUT_ACTIONS[action_to_remap]:
			item.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")

## This function should be connected to the reset button. It calls the create action list
## which clears all the current action button and then adds all the default action buttons
func _on_reset_button_pressed() -> void:
	on_reset_pressed.emit()
	on_button_pressed.emit()
	_create_action_list()
	send_only_announcement.emit("Values reset")
	send_interactive_items.emit(interactive_items_collection, text_for_interactive_items)

## This function should be connected to the exit button. It hides this menu and returns the user to
## the main menu.
func _on_exit_button_pressed() -> void:
	on_button_pressed.emit()
	send_interactive_items.emit([],[],"Now returning to main menu")
	self.hide()

## This function is responsible for changing a specific action from the Input map on the project
## settings to the event given. It translates the event to a keycode, the clears the action's
## keycode on the project settings and then adds the event into it. After that it updates the
## action list so that it reflects the change.
func change_input(action_to_remap: String, event: String) -> void:
	var event2 = InputEventKey.new()
	event2.keycode = OS.find_keycode_from_string(event)
	InputMap.action_erase_events(action_to_remap)
	InputMap.action_add_event(action_to_remap, event2)
	_update_action_list(action_to_remap,event2)
	print_debug("Changed rebind " + action_to_remap)

## This function should be called by another script to make the rebind menu appear. It shows itself
## and also sends the action list buttons along with the reset and exit button to the tts component
## for them to be voiced.
func show_rebind_menu() -> void:
	self.show()
	send_interactive_items.emit(interactive_items_collection, text_for_interactive_items,ANNOUNCEMENT)
