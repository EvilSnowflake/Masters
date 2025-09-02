extends Node2D
## This script aims to bridge the game stages and main menu. It helps setup the audio options
## and rebind menu to the menu screen, create the currently played game, and return the user
## from the game to the main menu.

## This variable references the menu screen from the hierarchy
@onready var menu_screen = %MenuScreen
## This variable references the menu music player on the hierarchy
@onready var menu_music = %Menu_Music

## This variable should contain a reference the audio options menu
@export var audio_options: Control
## This variable should contain a reference to the rebind menu
@export var rebind_menu: Control

func _ready() -> void:
	if menu_screen.has_method("set_audio_options") and audio_options != null:
		menu_screen.set_audio_options(audio_options)
	if menu_screen.has_method("set_rebind_menu") and rebind_menu != null:
		menu_screen.set_rebind_menu(rebind_menu)

## This function should be used to create a game after the user selects a stage. It stops
## the main menu music, creates a game instance with the preloaded game scene item, adds the
## game as a child to this scene, hides the main menu scene and set's up some methods of
## the game. After that it returns the new game made.
func create_game(num: int, propedia_end_num: int) -> Object:
	menu_music.playing = false
	const GAME = preload("res://scenes/game.tscn")
	var new_game = GAME.instantiate()
	new_game.global_position = global_position
	add_child(new_game)
	if (new_game.has_method("set_max_waves")):
		new_game.set_max_waves(propedia_end_num)
	if(new_game.has_method("read_stage_menu")):
		new_game.read_stage_menu(self)
	if(new_game.has_method("change_propedia")):
		new_game.change_propedia(num)
	menu_screen.hide()
	if(new_game.has_method("pause")):
		new_game.pause(2)
	return new_game

## This function should be used to get back to the main menu after finishing a stage. It
## resumes the main menu music and sows the main menu screen.
func exit_game():
	menu_screen.show()
	menu_music.playing = true

## This function should be called by the current game played. After finishing a stage or dying
## the game destroys itself and using this function it sends any stats the user had during the game,
## the number of the stage, and if the user died or not, all of which this function sends to the
## main menu to unlock a new stage if possible.
func unlock_next_stage(num: int, end_stats : Dictionary = {}, user_died: bool = false):
	menu_music.playing = true
	if(menu_screen.has_method("enable_propedia_button")):
		menu_screen.enable_propedia_button(num, end_stats, user_died)
