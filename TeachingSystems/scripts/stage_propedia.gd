extends Control

@onready var stage_number = %Stage_Number
@onready var stage_material = %Stage_Material

signal pressed_return

func change_labels(number: String, mat: String):
	stage_number.text = "Stage " + number + " material"
	stage_material.text = mat

func _process(_delta):
	if(visible == false):
		return
	var mouseClick = Input.is_action_pressed("MouseLeft")
	if(mouseClick):
		pressed_return.emit()
