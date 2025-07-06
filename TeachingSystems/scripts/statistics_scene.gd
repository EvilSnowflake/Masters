extends Control

@export var back_button: Button 
@export var labels_container: HBoxContainer
@export var texts_container: HBoxContainer
@export var stages_button: OptionButton

var _player_stats: Dictionary
signal calculate_score()
# Called when the node enters the scene tree for the first time.
func _ready():
	stages_button.select(0)
	back_button.pressed.connect(_on_back_button_pressed)
	stages_button.item_selected.connect(_on_stages_button_item_selected)

func set_player_stats(pstats: Dictionary):
	_player_stats = pstats

func _on_back_button_pressed():
	stages_button.clear()
	stages_button.add_item("stages",0)
	update_labels()
	self.hide()

func _on_stages_button_item_selected(index: int):
	var stage_name = "stage_"+str(index)
	if not _player_stats.has(stage_name):
		update_labels()
		print("No such stage!")
		return
	var stage: Dictionary = _player_stats[stage_name]
	update_labels(stage)
		

func set_stages_button_up():
	for stage: String in _player_stats:
		if stage.begins_with("stage") :
			stages_button.add_item(stage)

func update_labels(stats: Dictionary = {}):
	for label: Label in labels_container.get_children():
		if stats == {}:
			label.text = "0"
		else:
			var lbl_name: String = str(label.name)
			if stats.has(lbl_name):
				print(stats[lbl_name])
				label.text = str(stats[lbl_name])
