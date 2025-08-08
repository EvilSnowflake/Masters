extends Control

const STAGE_WORD: String = "STAGE_WORD_TEXT"
const MATERIAL_WORD: String = "MATERIAL_WORD_TEXT"

@onready var stage_number = %Stage_Number
@onready var stage_material = %Stage_Material

var _num: String
var _mat: String

signal pressed_return
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
signal send_only_announcement(announcement: String)
signal send_scene_for_signals(scene)

func change_labels(number: String, mat: String):
	print_debug("Cahanged labels")
	_num = number
	_mat = mat
	stage_number.text = tr(STAGE_WORD) + " " + number + " " + tr(MATERIAL_WORD)
	stage_material.text = mat

func _process(_delta):
	if(visible == false):
		return
	var mouseClick = Input.is_action_pressed("MouseLeft")
	if(mouseClick):
		pressed_return.emit()
		send_only_announcement.emit("")

func call_material() -> void:
	#send_interactive_items.emit([],[],"Stage " + _num + " Material \n" + _mat + " \n Press Left Click to Continue")
	send_only_announcement.emit("Stage " + _num + " Material \n" + _mat + " \n Press Left Click to Continue")
