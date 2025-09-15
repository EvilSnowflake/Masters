extends Control
## This script is attached to the controls menu in the game. It contains functions to show itself,
## hide and fill in the information about the multiplication table. Because the numbers on the
## table aren't always the same when the controls menu appears it calculates all the multiplications
## with one number, and then writes it on a label. Then it makes another label which contains the 
## next number and so on. After it creates all the labels it sends them to the tts component to 
## voice them one by one

const ANNOUNCEMENT = "Controls showcase. Here you can check the multiplication table and the controls"
const PROPEDIA_LABELBUTTON = preload("res://scenes/propedia_labelbutton.tscn")
const STAGE_BUTTON = preload("res://scenes/stage_button.tscn")

## This variable contains the return button from the hierarchy
@onready var return_button = %Return_Button

## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export var text_for_interactive_items: Array[String]
## This variable points to the component into which all the information about the multiplication
## table will be contained
@export var propedia_container: BoxContainer

## This variable contains the first number of the multiplicaiton table, it should be updated
## if the game has a different number
var _num_of_stages = 10
## This variable contains the second number of the multiplication table, it should be updated
## if the game has a different number
var _num_in_propedia = 10

## This signal is emitted when the user presses a button. Should make a sound.
signal play_button_sound()
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)

## This function is called when we want to return to the main menu, it hides the controls menu 
## and then announces that it returns to the main menu
func return_back():
	send_interactive_items.emit([],[],"Returning to main menu")
	hide()

## This function should be connected to the return button on the hierarchy, it calls the return 
## back function and plays the button sound
func _on_return_button_pressed():
	play_button_sound.emit()
	return_back()

## This function aims to fill the multiplication table in order for the player to be able to see
## it inside the game instead of seeing it from an outside source. First of all it requires 2
## numbers, usually given from the main menu. With those 2 numbers it creates the table and 
## breaks it into many smaller labels. It creates a new label, then puts all the multiplications
## for the first number into the label, it adds the label as a child to the propedia container 
## and also sends it to the tts component for the user to be able to hear it. Then moves
## to the next label.
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
