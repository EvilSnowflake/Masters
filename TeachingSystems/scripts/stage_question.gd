extends Control

const MAX_WRONG_NUM: int = 3
const CORRECT: String = "CORRECT_TEXT"
const WRONG: String = "WRONG_TEXT"
const RED: Color = Color(1.0,0.0,0.0,1.0)
const GREEN: Color = Color(0.0, 1.0, 0.0, 1.0)

## This variable should be filled with the current wave number the user is on
var _wave_num: int = 1
## This variable should be filled with the current stage number
var _stage_num: int = 1
## This variable should reference the countdown timer on the hierarchy
var _countdown_timer: Timer
## This variable should reference the outcome label on the hierarchy
var _outcome_label: Label
## This variable should be filled with the answer given by the user
var _answer_given: int = 0
## This variable should contain the first part of the question given
var first_num: int = 0
## This variable should contain the second part of the question given
var second_num: int = 0
## This variable should contain the max number that can be assigned as a question
var max_num: int = 10
## This variable should contain the biggest number in the multiplicaiton table
var num_in_propedia: int = 10
## This variable should contain a reference to the menu screen instance
var menu_screen_node : Control
## This variable should contain the correct answer to the current question
var correct_answer_num: int = 0
## This variable will be fileld with one of the wrong answers to the current quesiton
var wrong_answer_num: int = 0
## This variable should be filled with the buttons the user can interact with so that they
## are sent to the tts component and then be able to be voiced to the user
var button_array: Array[Control]
## This variable should contain the text inside the numbers sent to the tts component
## as descriptions.
var text_button_array: Array[String]

## This variable references the parent of the possible answers buttons on the hierarchy
@onready var possible_answers = %Possible_Answers
## This variable references the first number on the question given
@onready var question_num_1 = %Question_Num_1
## This variable references the second number on the question given
@onready var question_num_2 = %Question_Num_2

## This variable should reference the label before the question given
@export var pre_question: Label
## This variable should reference the parent of the outcome instance on the hierarchy
@export var result_item: ColorRect

## This signal should be emitted when the user answers the quetion given
signal answer_given(numbers: String, result: bool)
## This signal should be emitted when a button is pressed so that the appropriate sound is played
signal play_button_sound()
## This signal should be emitted when the user has made a lot of wrong answers
signal too_many_wrong_answers()
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
	_outcome_label = result_item.get_child(0)
	_countdown_timer = result_item.get_child(1)
	_countdown_timer.timeout.connect(_on_countdown_timer_timeout)

## This function should be called by another script. It takes in 2 numbers, the current wave and
## stage so that the appropriate variables are updated
func set_numbers(wave: int, stage: int):
	_wave_num = wave
	_stage_num = stage

## This function should be called when we want to offer the user a question. It picks 2 numbers
## that depend on a set number of variables that then fill the question for the user. Then
## the correct answer is given to one of the multiple chice buttons at random, after which
## we pick 2 false numbers for the other multiple choices and fill them accordingly. Depending
## on the answer each button will be connected to a function that checks the outcome if pressed.
func create_question():
	#pick a random number for the question
	#there are 2 possibilities,
	#	1: we pick a random number from 1 to max propedia num along with the stage number
	#	2: we pick a random number from the false answers given by the user
	#	3: we pick a random number that the user hasnt answered correctly
	#if the user has answered correctly to every question before, then pick 2 random numbers
	#from all possible numbers in the game, 1 -> (propedia_num)*(max_stages_num)
	#The end result is that there is a >33% chance that a previously false answer will be picked
	#A <33% chance that a previously correct answer will be picked
	#And a >33% chance that any number will be picked
	var prev_answers: Dictionary = {}
	second_num = 0
	first_num = 0
	var game_sts: Dictionary = {}
	if "_game_stats" in menu_screen_node:
		game_sts = menu_screen_node._game_stats
	if game_sts != {} and game_sts.has("answers"):
		prev_answers = game_sts["answers"]
	var values = []
	var keys = []
	if prev_answers != {}:
		values = prev_answers.values()
		keys = prev_answers.keys()
	var false_indexes = []
	var true_indexes = []
	for i in range(values.size()):
		if values[i] == false:
			false_indexes.append(i)
		else:
			true_indexes.append(i)
	var ran_num = randi_range(0,2)
	var false_prev_answers: Array[String] = [] 
	for index in false_indexes:
		var false_prev: String = keys[index]
		if false_prev.begins_with(str(_stage_num)) and int(false_prev.right(1))<=num_in_propedia:
			false_prev_answers.append(false_prev)
	wrong_answer_num = false_prev_answers.size()
	var true_prev_answers: Array[String] = [] 
	for index in true_indexes:
		var true_prev : String = keys[index]
		if true_prev.begins_with(str(_stage_num)) and int(true_prev.right(1))<=num_in_propedia:
			true_prev_answers.append(true_prev)
	if true_prev_answers.size() == num_in_propedia:
		first_num = randi_range(1,max_num)
		second_num = randi_range(1,num_in_propedia)
	else:
		first_num = _stage_num
	if (ran_num == 0 and second_num == 0) or false_prev_answers.size() == 0:
		second_num = randi_range(1,num_in_propedia)
	elif ran_num == 1 and second_num == 0:
		second_num = int(false_prev_answers.pick_random().right(1))
	elif ran_num == 2 and second_num == 0:
		while true:
			second_num = randi_range(1,num_in_propedia)
			var combination : String = str(first_num)+"|"+str(second_num)
			if true_prev_answers.has(combination):
				continue
			break
	#The 2 numbers are picked
	#Then we assign 1 of the 3 buttons to be the correct answer
	#And the other ones need to be wrong but not obviously wrong
	question_num_1.text = str(first_num)
	question_num_2.text = str(second_num)
	correct_answer_num = randi_range(0,possible_answers.get_child_count()-1)
	var last_answer: int = 0
	button_array = []
	text_button_array = []
	for i in range(possible_answers.get_child_count()):
		if(i == correct_answer_num):
			possible_answers.get_child(i).text = str(first_num*second_num)
			possible_answers.get_child(i).pressed.connect(_on_question_button_pressed.bind(first_num*second_num))
		else:
			var wrong_answer_number = randi_range(1,num_in_propedia)
			while(wrong_answer_number == second_num or wrong_answer_number == last_answer):
				wrong_answer_number = randi_range(1,num_in_propedia)
			possible_answers.get_child(i).text = str(first_num*wrong_answer_number)
			possible_answers.get_child(i).pressed.connect(_on_question_button_pressed.bind(first_num*wrong_answer_number))
			last_answer = wrong_answer_number
		button_array.append(possible_answers.get_child(i))
		text_button_array.append(possible_answers.get_child(i).text)
	button_array.append(pre_question)
	text_button_array.append(question_num_1.text + " times " + question_num_2.text)
	send_interactive_items.emit(button_array,text_button_array,"Question \n How much is \n " + str(first_num) + " \n times \n" + str(second_num))

## This function should be connected to all multiple choice buttons along with the answer they
## contain. If the number is correct then the outcome instance is shown with a correct word
## otherwise the false word is shown. After that a countodwn starts which when ending will return
## the player to the game.
func _on_question_button_pressed(answer: int):
	play_button_sound.emit()
	_answer_given = answer
	for i in range(possible_answers.get_child_count()):
		if(i == correct_answer_num):
			possible_answers.get_child(i).pressed.disconnect(_on_question_button_pressed)
		else:
			possible_answers.get_child(i).pressed.disconnect(_on_question_button_pressed)
	if answer == first_num*second_num:
		_outcome_label.text = CORRECT
		_outcome_label.set("theme_override_colors/font_color",GREEN)
	else:
		_outcome_label.text = WRONG
		_outcome_label.set("theme_override_colors/font_color",RED)
	result_item.show()
	send_only_announcement.emit(tr(_outcome_label.text))
	_countdown_timer.start()

## This function should be connected to the countdown timer, when finishing the result is hidden,
## an answer given signal is emitted and we check if the user has given too many wrong
## wrong answers so that we can then show them the multiplication table hint back at the game.
func _on_countdown_timer_timeout() -> void:
	result_item.hide()
	answer_given.emit(str(first_num)+"|"+str(second_num),_answer_given == first_num*second_num)
	if wrong_answer_num >= MAX_WRONG_NUM and _answer_given != first_num*second_num:
		too_many_wrong_answers.emit()
