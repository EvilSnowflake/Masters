extends Control

const RED = Color(1.0,0.0,0.0,1.0)
const WHITE = Color(1.0,1.0,1.0,1.0)
const GREEN = Color(0.0,1.0,0.0,1.0)

@export var back_button: Button 
@export var labels_container: HBoxContainer
@export var texts_container: HBoxContainer
@export var stages_button: OptionButton

var _num_of_stages
var _num_in_propedia
var _player_stats: Dictionary

signal calculate_score()
signal play_button_sound()

# Called when the node enters the scene tree for the first time.
func _ready():
	stages_button.select(0)
	back_button.pressed.connect(_on_back_button_pressed)
	stages_button.pressed.connect(_on_option_button_pressed)
	stages_button.item_selected.connect(_on_stages_button_item_selected)

func set_player_stats(pstats: Dictionary):
	_player_stats = pstats

func _on_back_button_pressed():
	play_button_sound.emit()
	stages_button.clear()
	stages_button.add_item("stages",0)
	update_labels()
	self.hide()

func _on_option_button_pressed():
	play_button_sound.emit()

func _on_stages_button_item_selected(index: int):
	play_button_sound.emit()
	var stage_name = "stage_"+str(index)
	if not _player_stats.has(stage_name):
		update_labels()
		print_debug("No such stage!")
		return
	var stage: Dictionary = _player_stats[stage_name]
	update_labels(stage,index)
		

func set_stages_button_up():
	for stage: String in _player_stats:
		if stage.begins_with("stage") :
			stages_button.add_item(stage)

func update_labels(stats: Dictionary = {}, stage_num: int = 0):
	for label: Label in labels_container.get_children():
		if stats == {}:
			label.text = "0"
			label.set("theme_override_colors/font_color",RED)
		else:
			var lbl_name: String = str(label.name)
			if stats.has(lbl_name):
				label.text = str(stats[lbl_name])
				label.set("theme_override_colors/font_color",check_numbers(lbl_name,stats[lbl_name],stage_num))

func set_num_of_stages(num: int):
	_num_of_stages = num

func set_num_in_propedia(num: int):
	_num_in_propedia = num

func check_numbers(stat_name: String, stat_number: int, stage_num: int) -> Color:
	if _num_of_stages == null or _num_in_propedia == null:
		return WHITE
	if stat_name == "total_enemies":
		if stat_number < stage_num*_num_in_propedia:
			return RED
		else:
			return GREEN
	elif stat_name == "total_time":
		if stat_number > stage_num*_num_in_propedia*3:
			return RED
		else:
			return GREEN
	elif stat_name == "correct_answers":
		if stat_number == 0:
			return RED
		else:
			return GREEN
	elif stat_name == "wrong_answers":
		if stat_number > 0:
			return RED
		else:
			return GREEN
	elif stat_name == "score":
		if stat_number < _num_of_stages*_num_in_propedia:
			return RED
		else:
			return GREEN
	else:
		return WHITE
