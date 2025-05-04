extends Control

@onready var return_button = %Return_Button

func return_back():
	hide()

func _on_return_button_pressed():
	return_back()
