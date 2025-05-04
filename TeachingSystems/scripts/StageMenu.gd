extends Node2D

@onready var menu_screen = %MenuScreen
@onready var color_rect = %ColorRect
@onready var menu_music = %Menu_Music

func create_game(num: int):
	menu_music.playing = false
	const GAME = preload("res://scenes/game.tscn")
	var new_game = GAME.instantiate()
	new_game.global_position = global_position
	add_child(new_game)
	if(new_game.has_method("read_stage_menu")):
		new_game.read_stage_menu(self)
	if(new_game.has_method("change_propedia")):
		new_game.change_propedia(num)
	menu_screen.hide()
	if(new_game.has_method("pause")):
		new_game.pause(2)

func exit_game():
	menu_screen.show()
	menu_music.playing = true

func unlock_next_stage(num: int):
	menu_music.playing = true
	if(menu_screen.has_method("enable_propedia_button")):
		menu_screen.enable_propedia_button(num)
