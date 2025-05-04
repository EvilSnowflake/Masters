extends Control

@onready var menu_screen = %MenuScreen

@onready var color_rect = %ColorRect

func _process(_delta):
	if(!visible or menu_screen == null):
		return
		
	var mouseClick = Input.is_action_pressed("MouseLeft")
	if(mouseClick):
		color_rect.call("trans",self,menu_screen)
