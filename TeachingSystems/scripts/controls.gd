extends Control

const ANNOUNCEMENT = "Controls showcase. Here you can check the multiplication table and the controls"
const PROPEDIA_LABELBUTTON = preload("res://scenes/propedia_labelbutton.tscn")
const STAGE_BUTTON = preload("res://scenes/stage_button.tscn")

@onready var return_button = %Return_Button

@export var interactive_items_collection: Array[Control]
@export var text_for_interactive_items: Array[String]
@export var propedia_container: BoxContainer

var _num_of_stages = 10
var _num_in_propedia = 10

signal play_button_sound()
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
signal send_only_announcement(announcement: String)

func return_back():
	send_interactive_items.emit([],[],"Returning to main menu")
	hide()

func _on_return_button_pressed():
	play_button_sound.emit()
	return_back()

func show_controls_menu(num1: int, num2: int) -> void:
	_num_of_stages = num1
	_num_in_propedia = num2
	self.show()
	var counter = -1
	for child in propedia_container.get_children():
		counter += 1
		if counter == 0:
			continue
		propedia_container.remove_child(child)
		child.queue_free()
	for i in range(1,_num_of_stages+1):
		var numsLabel = PROPEDIA_LABELBUTTON.instantiate()
		var sounded_text = ""
		for j in range(1,_num_in_propedia+1):
			numsLabel.text = numsLabel.text + str(i) + "x" + str(j) + "=" + str(i*j) + " "
			sounded_text = sounded_text + str(i) + " times " + str(j) + " equals" + str(i*j) + "\n"
		propedia_container.add_child(numsLabel)
		interactive_items_collection.append(numsLabel)
		text_for_interactive_items.append(sounded_text)
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT)
