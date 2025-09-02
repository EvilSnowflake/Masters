extends Control
## This script is in charge of showing the user the current stage's multiplication table. It should
## receive the material of the table from the current game instance, show it to the player
## and then wait for the player to move along.

const STAGE_WORD: String = "STAGE_WORD_TEXT"
const MATERIAL_WORD: String = "MATERIAL_WORD_TEXT"

## This variable references the label containing the stage number label in the hierarchy
@onready var stage_number = %Stage_Number
## This variable references the stage material label in the hierarchy.
@onready var stage_material = %Stage_Material

## This variable should be filled with the current stage number of the game
var _num: String
## This variable should be filler with the multiplication table material of the current stage of 
## the game.
var _mat: String

## This signal should be emitted when the user moves on from the stage material instance
signal pressed_return
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)
## This signal should be emitted if the scene contains children that want to use the tts component
## By emitting it with the child scene their signals are connected to the tts.
signal send_scene_for_signals(scene)

## This function should be called by another scene to fill the appropriate labels for the user. It
## takes in the current stage number along with the multiplication table material, which then
## fills in the appropriate variables and then replaces the text on the right labels.
func change_labels(number: String, mat: String):
	print_debug("Cahanged labels")
	_num = number
	_mat = mat
	stage_number.text = tr(STAGE_WORD) + " " + number + " " + tr(MATERIAL_WORD)
	stage_material.text = mat

# This function checks for a mouse click by the user. If it detects one, it hides itself
func _process(_delta):
	if(visible == false):
		return
	var mouseClick = Input.is_action_pressed("MouseLeft")
	if(mouseClick):
		pressed_return.emit()
		send_only_announcement.emit("")

## This function should be called by another scene to send the material and the stage number to
## the tts component along with a announcement so that the player knows to left click to continue.
func call_material() -> void:
	send_only_announcement.emit("Stage " + _num + " Material \n" + _mat + 
	" \n Press Left Click to Continue")
