extends Control

var _wave_num: int = 1
var _stage_num: int = 1
var first_num: int = 0
var second_num: int = 0
var max_num: int = 10
var num_in_propedia: int = 10
var menu_screen_node : Control


@onready var possible_answers = %Possible_Answers
@onready var question_num_1 = %Question_Num_1
@onready var question_num_2 = %Question_Num_2

var correct_answer_num = 0
signal answer_given(numbers: String, result: bool)
signal play_button_sound()

func _ready():
	pass

func set_numbers(wave: int, stage: int):
	_wave_num = wave
	_stage_num = stage

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
	print(game_sts)
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
	print_debug(false_indexes)
	print_debug(true_indexes)
	
	var ran_num = randi_range(0,2)
	print_debug(ran_num)
	
	
	print_debug("False previous answers")
	var false_prev_answers: Array[String] = [] 
	for index in false_indexes:
		var false_prev: String = keys[index]
		if false_prev.begins_with(str(_stage_num)) and int(false_prev.right(1))<=num_in_propedia:
			false_prev_answers.append(false_prev)
	print_debug(false_prev_answers)
	print_debug("Correct previous answers")
	var true_prev_answers: Array[String] = [] 
	for index in true_indexes:
		var true_prev : String = keys[index]
		if true_prev.begins_with(str(_stage_num)) and int(true_prev.right(1))<=num_in_propedia:
			true_prev_answers.append(true_prev)
	print_debug(true_prev_answers)
	
	if true_prev_answers.size() == num_in_propedia:
		first_num = randi_range(1,max_num)
		second_num = randi_range(1,num_in_propedia)
	else:
		first_num = _stage_num
	
	if (ran_num == 0 and second_num == 0) or false_prev_answers.size() == 0:
	#	while true:
	#		second_num = randi_range(1,num_in_propedia)
	#		var combination : String = str(first_num)+"|"+str(second_num)
	#		if not prev_answers.has(combination):
	#			break
	#		if prev_answers[combination] == false:
	#			break
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
	for i in range(possible_answers.get_child_count()):
		if(i == correct_answer_num):
			possible_answers.get_child(i).text = str(first_num*second_num)
			possible_answers.get_child(i).pressed.connect(_on_question_button_pressed.bind(first_num*second_num))
		else:
			var wrong_answer_num = randi_range(1,num_in_propedia)
			while(wrong_answer_num == second_num or wrong_answer_num == last_answer):
				wrong_answer_num = randi_range(1,num_in_propedia)
			possible_answers.get_child(i).text = str(first_num*wrong_answer_num)
			possible_answers.get_child(i).pressed.connect(_on_question_button_pressed.bind(first_num*wrong_answer_num))
			last_answer = wrong_answer_num

func _on_question_button_pressed(answer: int):
	play_button_sound.emit()
	for i in range(possible_answers.get_child_count()):
		if(i == correct_answer_num):
			possible_answers.get_child(i).pressed.disconnect(_on_question_button_pressed)
		else:
			possible_answers.get_child(i).pressed.disconnect(_on_question_button_pressed)
	answer_given.emit(str(first_num)+"|"+str(second_num),answer == first_num*second_num)
