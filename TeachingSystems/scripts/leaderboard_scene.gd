@tool
extends Control
## This script gives function to the leaderboard scene on the game. Using the name of the
## leaderboard from Silent Wolf it gets all the highscores from every user registered
## and returns a set amount of them for the user to see sorted. If there are no scores
## or the game isn't able to acquire them then the user is informed.

const SCORE_ITEM = preload("res://scenes/score_item.tscn")
const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
const NOSCORES = "NO_SCORES_TEXT"
const LOADING = "LOADING_SCORES_TEXT"
const ANNOUNCEMENT: String = "Here are the leaderboards. You can see the top 5 total scores from all the accounts created." #NOT TRANSLATED

## This variable determines what number the current item takes on the list of leaderboard
var list_index = 0
## This variable should contain the name of the laeaderboard so taht the scene knows
## what data it should take
var ld_name = "main"
## This variable determines the number of items shown to the user
var max_scores = 5

## This variable references the back button on the hierarchy
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer/BackButton
## This variable references the message label on the hierarchy
@onready var message_label = $MarginContainer/VBoxContainer/HBoxContainer3/MessageLabel
## This variable references the scores container on the hierarchy
@onready var leader_container = $MarginContainer/VBoxContainer/LeaderContainer
## This variable references the audio player for the button sound on the hierarchy
@onready var button_audio_player = %ButtonAudioPlayer
## This variable references the wait timer on the hierarchy
@onready var wait_timer = %WaitTimer
## This variable references the panel that stops the user from clicking anything on the hierarchy
@onready var anti_click_panel = %AntiClickPanel

## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export var text_for_interactive_items: Array[String]

## This signal is emitted when the user presses a button. Should make a sound.
signal play_button_sound()
## This signal is emitted when entering the scene. It send all the control object on the scene
## the user can interact with so that the tts component can voice their descriptions and 
## an announcement optionally
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
## This signal is emitted if the scene need to voice a message to the user.
signal send_only_announcement(announcement: String)
## This signal should be emitted if the scene contains children that want to use the tts component
## By emitting it with the child scene their signals are connected to the tts.
signal send_scene_for_signals(scene)

func _ready():
	back_button.pressed.connect(_on_CloseButton_pressed)
	play_button_sound.connect(_on_button_play_sound)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	var scores = SilentWolf.Scores.scores
	if ld_name in SilentWolf.Scores.leaderboards:
		scores = SilentWolf.Scores.leaderboards[ld_name]
	var local_scores = SilentWolf.Scores.local_scores
	if len(scores) > 0: 
		render_board(scores, local_scores)
	else:
		show_message(tr(LOADING))
		var sw_result = await SilentWolf.Scores.get_scores().sw_get_scores_complete
		scores = sw_result.scores
		hide_message()
		render_board(scores, local_scores)

## This function accepts all the scres retrieved and the local scores to show to the user
func render_board(scores: Array, local_scores: Array) -> void:
	var all_scores = scores
	if (ld_name in SilentWolf.Scores.ldboard_config and 
	is_default_leaderboard(SilentWolf.Scores.ldboard_config[ld_name])):
		all_scores = merge_scores_with_local_scores(scores, local_scores, max_scores)
		if scores.is_empty() and local_scores.is_empty():
			show_message(tr(NOSCORES))
			send_interactive_items.emit(interactive_items_collection,
			text_for_interactive_items)
	else:
		if scores.is_empty():
			show_message(tr(NOSCORES))
			send_interactive_items.emit(interactive_items_collection,
			text_for_interactive_items)
	if all_scores.is_empty():
		for score in scores:
			add_item(score.player_name, str(int(score.score)))
		send_interactive_items.emit(interactive_items_collection,
		text_for_interactive_items,"Scores Found \n" + ANNOUNCEMENT)
	else:
		for score in all_scores:
			add_item(score.player_name, str(int(score.score)))
		send_interactive_items.emit(interactive_items_collection,
		text_for_interactive_items,"Scores Found \n" + ANNOUNCEMENT)

## This function checks the configuration of the leaderboard so that we know if its
## the default one
func is_default_leaderboard(ld_config: Dictionary) -> bool:
	var default_insert_opt = (ld_config.insert_opt == "keep")
	var not_time_based = !("time_based" in ld_config)
	return default_insert_opt and not_time_based

## This function checks the local and received scores and if any local ones are not in the
## received ones then it adds them and then returns the resulting array sorted.
func merge_scores_with_local_scores(scores: Array, local_scores: Array,
 max_scores: int=10) -> Array:
	if local_scores:
		for score in local_scores:
			var in_array = score_in_score_array(scores, score)
			if !in_array:
				scores.append(score)
			scores.sort_custom(sort_by_score);
	if scores.size() > max_scores:
		var new_size = scores.resize(max_scores)
	return scores

## This function compares two scores so that it returns true or false if one is larger or smaller.
## If a score is bigger then it returns true, if b is bigger then it returns false otherwise
## it returns true
func sort_by_score(a: Dictionary, b: Dictionary) -> bool:
	if a.score > b.score:
		return true;
	else:
		if a.score < b.score:
			return false;
		else:
			return true;

## This function returns true if all scores in the variable new scores are in the variable 
## scores.
func score_in_score_array(scores: Array, new_score: Dictionary) -> bool:
	var in_score_array =  false
	if !new_score.is_empty() and !scores.is_empty():
		for score in scores:
			if score.score_id == new_score.score_id:
				in_score_array = true
	return in_score_array

## This function creates a score item from a preloaded scene, into which it inserts the name a value
## after which it adds it to the list and sends it to the main list and to the tts component.
func add_item(player_name: String, score_value: String) -> void:
	var item = SCORE_ITEM.instantiate()
	list_index += 1
	var labelCont = item.get_child(1).get_child(0)
	labelCont.get_node("PlayerName").text = str(list_index) + str(". ") + player_name
	labelCont.get_node("Score").text = score_value
	item.offset_top = list_index * 100
	leader_container.add_child(item)
	interactive_items_collection.append(item)
	text_for_interactive_items.append("Player " + player_name + " \n has score " + score_value)

## This function takes a text message and applies the text to the message label after which
## it shows the label to the user and then sends it to the tts component.
func show_message(text: String = "") -> void:
	message_label.text = text
	message_label.show()
	send_only_announcement.emit(text)

## This function clears the text from the message label and then hides it.
func hide_message()-> void:
	message_label.text = ""
	message_label.hide()

## This function deletes all score items in the leaderboard in order to clear it from previous
## scores.
func clear_leaderboard() -> void:
	if leader_container.get_child_count() > 0:
		var children = leader_container.get_children()
		for c in children:
			leader_container.remove_child(c)
			c.queue_free()

## This function should connect to the close button. After playing the button sound
## and wait for some time it returns the user to the main menu.
func _on_CloseButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	var scene_name = SilentWolf.scores_config.open_scene_on_close
	SWLogger.info("Closing SilentWolf leaderboard, switching to scene: " + str(scene_name))
	get_tree().change_scene_to_file(scene_name)

## This function should be called when the user presses a button so that it plays
## an audio clip
func _on_button_play_sound() -> void:
	button_audio_player.play()

## This function should be connected to the wait timer. When the anti click panel appears
## so that the user can't interact with the scene, the timer should start and then 
## after the timer ends it informs the scene to hide the anti click panel.
func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
