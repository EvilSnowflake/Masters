extends Control

const PRESS_KEY: String = "PRESSKEY_TEXT"

@onready var input_button_scene = preload("res://scenes/input_button.tscn")

@export var action_list: VBoxContainer
@export var reset_button: Button
@export var exit_button: Button
var _is_remapping: bool = false
var _action_to_remap: String = ""
var _remapping_button: Button = null

const INPUT_ACTIONS = {
	"Up": "UP",
	"Down": "DOWN",
	"Left": "LEFT",
	"Right": "RIGHT",
	"Escape": "PAUSE"
}

signal keycode_changed(action_to_remap: String, event_text: String)
signal on_button_pressed()
signal on_reset_pressed()

func _ready() -> void:
	_create_action_list()
	reset_button.pressed.connect(_on_reset_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
func _create_action_list() -> void:
	InputMap.load_from_project_settings()
	if action_list == null:
		print_debug("Action list is null!")
		return
	for item in action_list.get_children():
		item.queue_free()
	
	for action in INPUT_ACTIONS:
		var button = input_button_scene.instantiate()
		var action_label: Label = button.find_child("LabelAction")
		var input_label: Label = button.find_child("LabelInput")
		
		action_label.text = INPUT_ACTIONS[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
		
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button,action))

func _on_input_button_pressed(button: Button, action: String) -> void:
	on_button_pressed.emit()
	if !_is_remapping:
		_is_remapping = true
		_action_to_remap = action
		_remapping_button = button
		button.find_child("LabelInput").text = tr(PRESS_KEY)

func _input(event) -> void:
	if _is_remapping:
		if (event is InputEventKey) || (event is InputEventMouseButton && event.pressed):
			change_input(_action_to_remap,event.as_text())
			#InputMap.action_erase_events(_action_to_remap)
			#InputMap.action_add_event(_action_to_remap, event)
			print_debug(" Action to remap : " + _action_to_remap + " , Event : " + event.as_text() + " , Remapping Button : " + str(_remapping_button))
			#print_debug(event)
			#var event2 = InputEventKey.new()
			#event2.keycode = OS.find_keycode_from_string(event.as_text())
			#print_debug(event2)
			#_update_action_list(_action_to_remap,event)
			keycode_changed.emit(_action_to_remap, event.as_text())
			
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
			
			_is_remapping = false
			_action_to_remap = ""
			_remapping_button = null
			
			accept_event()
			
func _update_action_list(action_to_remap: String, event) -> void:
	#print_debug(" Action to remap : " + INPUT_ACTIONS[action_to_remap])
	for item: Button in action_list.get_children():
		#print_debug("Current item label action : " + item.find_child("LabelAction").text)
		if item.find_child("LabelAction").text == INPUT_ACTIONS[action_to_remap]:
			item.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")

func _on_reset_button_pressed() -> void:
	on_reset_pressed.emit()
	on_button_pressed.emit()
	_create_action_list()

func _on_exit_button_pressed() -> void:
	on_button_pressed.emit()
	self.hide()

func change_input(action_to_remap: String, event: String):
	#if action_to_remap == "" or event == "":
	#	print_debug("Action or Event does not exist")
	var event2 = InputEventKey.new()
	event2.keycode = OS.find_keycode_from_string(event)
	InputMap.action_erase_events(action_to_remap)
	InputMap.action_add_event(action_to_remap, event2)
	_update_action_list(action_to_remap,event2)
	print_debug("Changed rebind " + action_to_remap)
	
