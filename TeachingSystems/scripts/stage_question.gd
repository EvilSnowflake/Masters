extends Control

var _wave_num: int = 1
var _stage_num: int = 1
var first_num: int = 1
var second_num: int = 1

@onready var possible_answers = %Possible_Answers
@onready var question_num_1 = %Question_Num_1
@onready var question_num_2 = %Question_Num_2

var correct_answer_num = 0
signal answer_given(numbers: String, result: bool)

func set_numbers(wave: int, stage: int):
	_wave_num = wave
	_stage_num = stage

func create_question():
	first_num = randi_range(1,_stage_num)
	second_num = randi_range(1,_wave_num)
	question_num_1.text = str(first_num)
	question_num_2.text = str(second_num)
	correct_answer_num = randi_range(0,possible_answers.get_child_count()-1)
	var last_answer: int = 0
	for i in range(possible_answers.get_child_count()):
		if(i == correct_answer_num):
			possible_answers.get_child(i).text = str(first_num*second_num)
			possible_answers.get_child(i).pressed.connect(_on_question_button_pressed.bind(first_num*second_num))
		else:
			var wrong_answer_num = randi_range(1,100)
			while(wrong_answer_num == first_num*second_num or wrong_answer_num == last_answer):
				wrong_answer_num = randi_range(1,100)
			possible_answers.get_child(i).text = str(wrong_answer_num)
			possible_answers.get_child(i).pressed.connect(_on_question_button_pressed.bind(wrong_answer_num))
			last_answer = wrong_answer_num

func _on_question_button_pressed(answer: int):
	for i in range(possible_answers.get_child_count()):
		if(i == correct_answer_num):
			possible_answers.get_child(i).pressed.disconnect(_on_question_button_pressed)
		else:
			possible_answers.get_child(i).pressed.disconnect(_on_question_button_pressed)
	answer_given.emit(str(first_num)+"|"+str(second_num),answer == first_num*second_num)
