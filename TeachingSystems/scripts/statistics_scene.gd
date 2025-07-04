extends Control

@export var back_button: Button 
@export var labels_container: HBoxContainer
@export var texts_container: HBoxContainer
@export var stages_button: OptionButton

var _player_stats: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	stages_button.select(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_player_stats(pstats: Dictionary):
	_player_stats = pstats
	print("Stats moved")
	print(pstats)
