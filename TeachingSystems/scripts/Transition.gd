extends ColorRect
## This script can be used to transition between scenes. Currently it's used to better move the user
## from the starting screen with the game's title to the main menu.

## This variable should be filled with the item that will disappear after the procedure.
var _graphicVanish
## This variable should be filled with the item that will appear after the procedure.
var _graphicAppear
## This variable points to the animation player in charge of darkening and lightening the screen
## during transition.
var _color_rect_animations: AnimationPlayer

## This variable should reference the starting interface scene.
@export
var starting_interface : Control

func _ready() -> void:
	if get_child_count() > 0:
		_color_rect_animations = get_child(0)

# While running this script check if the graphic is currently no transparent. If it is completely 
# non transparent then we show the item that should appear and hide the one that should disappear.
func _process(_delta):
	if(color.a == 1):
		_graphicVanish.visible = false
		_graphicVanish.mouse_filter = MOUSE_FILTER_IGNORE
		if _graphicAppear != null:
			_graphicAppear.visible = true
			_graphicAppear.mouse_filter = MOUSE_FILTER_STOP
	if(color.a != 0):
		return

## This function should be called by the scene that wants to transition between two screens. The
## first item inputed will disappear while the secon one will appear after darkening the screen.
func trans(van = null ,app = null) -> void:
	_graphicVanish = van
	_graphicAppear = app
	_color_rect_animations.play("Appear")
	if _graphicAppear != null:
		_color_rect_animations.queue("Fade")
