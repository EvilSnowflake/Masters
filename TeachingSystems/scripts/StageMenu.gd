extends Node2D

@onready var menu_screen = %MenuScreen
@onready var color_rect = %ColorRect
@onready var menu_music = %Menu_Music

@export var audio_options: Control
@export var rebind_menu: Control

func _ready() -> void:
	if menu_screen.has_method("set_audio_options") and audio_options != null:
		menu_screen.set_audio_options(audio_options)
	if menu_screen.has_method("set_rebind_menu") and rebind_menu != null:
		menu_screen.set_rebind_menu(rebind_menu)

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

func exit_game():
	menu_screen.show()
	menu_music.playing = true

func unlock_next_stage(num: int, end_stats : Dictionary = {}, user_died: bool = false):
	menu_music.playing = true
	if(menu_screen.has_method("enable_propedia_button")):
		menu_screen.enable_propedia_button(num, end_stats, user_died)
