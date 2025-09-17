extends Control
## This script should be attached to the statistics scene instance. There the user can see all the
## progress they made during gameplay. They can choose one of the stages they have finished
## and read how many right or wrong answers it had answered, the enemies defeated, how much time
## it took them to finish that stage and the total score for the stage.

const RED = Color(1.0,0.0,0.0,1.0)
const WHITE = Color(1.0,1.0,1.0,1.0)
const GREEN = Color(0.0,1.0,0.0,1.0)
const ANNOUNCEMENT: String = "Statistics Menu. Here you can check the statistics for each stage you have beaten or attempted to beat"

## This variable should contain a reference to the back button on the hierarchy
@export var back_button: Button 
## This variable should contain a reference to the labels container on the hierarchy
@export var labels_container: HBoxContainer
## This variable should contain a reference to the texts container on the hierarchy
@export var texts_container: HBoxContainer
## This variable should contain a reference to the stage options button on the hierarchy
@export var stages_button: OptionButton
## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export var text_for_interactive_items: Array[String]

## This variable should contain the number of stages the game has
var _num_of_stages
## This variable should contain the number of waves each stage has in this game
var _num_in_propedia
## This variable should contain the players game stats
var _player_stats: Dictionary

## This signal should be emitted when the user presses a button, the appropriate audio clip
## should be played
signal play_button_sound()
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)

# When entering the menu the options button selects the first item which contains nothing,
# and also it contains any functions to the appropriate objects.
func _ready():
	stages_button.select(0)
	back_button.pressed.connect(_on_back_button_pressed)
	stages_button.item_selected.connect(_on_stages_button_item_selected)
	stages_button.item_focused.connect(_on_stages_button_item_focused)
	stages_button.pressed.connect(_on_stages_button_pressed)
	
	for i in range(labels_container.get_child_count()):
		labels_container.get_child(i).focus_entered.connect(_on_label_focused.bind(i))

## This function should be used by another script to pass on the player's game stats
func set_player_stats(pstats: Dictionary):
	_player_stats = pstats

## This function should be connected to the back button. It clears any stages added to the stage
## options button, clears any labels changed and hides itself.
func _on_back_button_pressed():
	play_button_sound.emit()
	stages_button.clear()
	stages_button.add_item("stages",0)
	update_labels()
	self.hide()

## This function should be connected to the stage options button. After selecting an index, we use
## the index to find the data on the specific stage selected if they exist. After obtaining the 
## user's data we distribute them to the appropriate labels on the menu so that the user can see
## them and then send the text to the tts component so that they can also hear the data.
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
	for i in range(labels_container.get_child_count()):
		collected_data += tr(texts_container.get_child(i).text).replace("\n"," ") + " " + labels_container.get_child(i).text + "\n"
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,collected_data)

## This function should be connected to the stage options button. After focusing on an item
## we send the option's text to the tts component so that the user can hear the contents
func _on_stages_button_item_focused(index: int) -> void:
	var item_text = stages_button.get_item_text(index)
	send_only_announcement.emit(tr(item_text))

## This function should be connected to the stage options button. After pressing it
## we inform the user that it was pressed and we play a sound effect.
func _on_stages_button_pressed() -> void:
	play_button_sound.emit()
	send_interactive_items.emit([],[],"Select a stage from the options to learn your progress")

## This function fills the stage options button with all the stage numbers the user
## has been in as options.
func set_stages_button_up():
	stages_button.clear()
	for stage: String in _player_stats:
		if stage.begins_with("stage") :
			stages_button.add_item(stage)
	

## This function should be called when the user selects a stage in the options button.
## If there is a stage in the user's saved game data, it takes the statistics from that
## and for each label on the labels container we take the appropriate statistic and write
## the number there. 
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

## This function should be used to update the num of stages variable
func set_num_of_stages(num: int):
	_num_of_stages = num

## This function should be used to update the num in propedia variable
func set_num_in_propedia(num: int):
	_num_in_propedia = num

## This function should be used to mark the numbers on the labels filled with the user's
## stage data. We have set some limits to what each stat should have. If the user has
## a smalled number we mark it with a red color, if its equal or better it gets a green color.
## The total enemies should be more than the stage number times the wave number. The
## total time should be more than the stage number times the wave number times 3. If there
## are 0 correct answers its marked red, otherwise its green. Any wrong answers above 0 are
## marked red. The score should better than the number of stages times the number of waves.
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

## This function should be used to set the variables correctly. It requeires the player
## game stats, the stages number and the waves number.
func show_statistics_menu(pstats: Dictionary, stg_num: int, prp_num: int) -> void:
	set_player_stats(pstats)
	set_stages_button_up()
	set_num_of_stages(stg_num)
	set_num_in_propedia(prp_num)
	self.show()
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT)
	if stages_button.item_count > 0:
		update_labels(_player_stats["stage_1"],0)

## This function should be connected to all labels. After being focused the label sends its
## text to the tts component for it to be voiced.
func _on_label_focused(chld_indx: int) -> void:
	send_only_announcement.emit(labels_container.get_child(chld_indx).text)
