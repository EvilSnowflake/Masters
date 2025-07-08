extends Control

@onready var return_button = %Return_Button

signal play_button_sound()

func return_back():
	hide()

func _on_return_button_pressed():
	play_button_sound.emit()
	return_back()
