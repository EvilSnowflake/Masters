extends Control

const RED = Color(1.0,0.0,0.0,1.0)
const WHITE = Color(1.0,1.0,1.0,1.0)
const GREEN = Color(0.0,1.0,0.0,1.0)
const ANNOUNCEMENT: String = "Statistics Menu. Here you can check the statistics for each stage you have beaten or attempted to beat"

@export var back_button: Button 
@export var labels_container: HBoxContainer
@export var texts_container: HBoxContainer
@export var stages_button: OptionButton
@export var interactive_items_collection: Array[Control]
@export var text_for_interactive_items: Array[String]

var _num_of_stages
var _num_in_propedia
var _player_stats: Dictionary

#signal calculate_score()
signal play_button_sound()
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
signal send_only_announcement(announcement: String)

# Called when the node enters the scene tree for the first time.
func _ready():
	stages_button.select(0)
	back_button.pressed.connect(_on_back_button_pressed)
	stages_button.item_selected.connect(_on_stages_button_item_selected)
	stages_button.item_focused.connect(_on_stages_button_item_focused)
	stages_button.pressed.connect(_on_stages_button_pressed)
	#for lbls in labels_container.get_children():
	#	lbls.focus_entered.connect(_on_label_focused.bind(lbls.text))
	for i in range(labels_container.get_child_count()):
		labels_container.get_child(i).focus_entered.connect(_on_label_focused.bind(i))

func set_player_stats(pstats: Dictionary):
	_player_stats = pstats

func _on_back_button_pressed():
	play_button_sound.emit()
	stages_button.clear()
	stages_button.add_item("stages",0)
	update_labels()
	self.hide()

func _on_stages_button_item_selected(index: int):
	play_button_sound.emit()
	var stage_name = "stage_"+str(index+1)
	if not _player_stats.has(stage_name):
		update_labels()
		print_debug("No such stage!")
	else:
		var stage: Dictionary = _player_stats[stage_name]
		update_labels(stage,index)
	
	var collected_data: String = "Selected " + stage_name + "\n" + "Your performance for the stage is \n"
	#send_only_announcement.emit(collected_data)
	for i in range(labels_container.get_child_count()):
		collected_data += tr(texts_container.get_child(i).text).replace("\n"," ") + " " + labels_container.get_child(i).text + "\n"
		#print_debug(" The numbers are: " + texts_container.get_child(i).text + " " + labels_container.get_child(i).text)
		#send_only_announcement.emit("Your performance for the stage is: " + tr(texts_container.get_child(i).text) + " " + labels_container.get_child(i).text)
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,collected_data)

func _on_stages_button_item_focused(index: int) -> void:
	var item_text = stages_button.get_item_text(index)
	send_only_announcement.emit(tr(item_text))

func _on_stages_button_pressed() -> void:
	play_button_sound.emit()
	send_interactive_items.emit([],[],"Select a stage from the options to learn your progress")

func set_stages_button_up():
	stages_button.clear()
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

func show_statistics_menu(pstats: Dictionary, stg_num: int, prp_num: int) -> void:
	set_player_stats(pstats)
	set_stages_button_up()
	set_num_of_stages(stg_num)
	set_num_in_propedia(prp_num)
	self.show()
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT)

func _on_label_focused(chld_indx: int) -> void:
	send_only_announcement.emit(labels_container.get_child(chld_indx).text)
	#print_debug(chld_indx)
