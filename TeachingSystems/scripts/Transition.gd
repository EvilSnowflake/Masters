extends ColorRect

var _graphicVanish
var _graphicAppear
var _color_rect_animations: AnimationPlayer
@export
var starting_interface : Control

func _ready() -> void:
	if get_child_count() > 0:
		_color_rect_animations = get_child(0)

func _process(_delta):
	if(color.a == 1):
		_graphicVanish.visible = false
		_graphicVanish.mouse_filter = MOUSE_FILTER_IGNORE
		if _graphicAppear != null:
			_graphicAppear.visible = true
			_graphicAppear.mouse_filter = MOUSE_FILTER_STOP
	
	if(color.a != 0):
		return

func trans(van = null ,app = null) -> void:
	_graphicVanish = van
	_graphicAppear = app
	_color_rect_animations.play("Appear")
	if _graphicAppear != null:
		_color_rect_animations.queue("Fade")
