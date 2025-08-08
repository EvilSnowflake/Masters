extends Control

const PROCESSING: String = "PROCESSING_TEXT"
const CODE_CANT_SEND: String = "CODE_CANT_SENT_TEXT"
const PASS_CANT_RESET: String = "PASS_CANT_RESET_TEXT"
const RED: Color = Color(1.0,0.0,0.0,1.0)
const WHITE: Color = Color(1.0,1.0,1.0,1.0)
const ANNOUNCEMENT: String = "Here you can reset your password. By writing your username and then inputing a code sent to your email you can then write a new password. You can move between input boxes with enter and not with the directional buttons" #NOT TRANSLATED

var player_name = null
var login_scene = "res://scenes/login_screen.tscn"

@onready var pwd_reset_form_container = $MarginContainer/PwdResetFormContainer
@onready var request_form_container = $MarginContainer/RequestFormContainer
@onready var password_changed_container = $MarginContainer/PasswordChangedContainer
@onready var back_button = $MarginContainer/BackButtonContainer/HBoxContainer2/BackButton
@onready var pwd_reset_info_label = $MarginContainer/PwdResetFormContainer/HBoxContainer5/VBoxContainer/InfoLabel
@onready var request_form_info_label = $MarginContainer/RequestFormContainer/HBoxContainer5/VBoxContainer/InfoLabel
@onready var close_button = $MarginContainer/PasswordChangedContainer/HBoxContainer5/CloseButton
@onready var pwd_submit_button = $MarginContainer/PwdResetFormContainer/HBoxContainer5/SubmitButton
@onready var rf_submit_button = $MarginContainer/RequestFormContainer/HBoxContainer5/SubmitButton
@onready var rf_name_line_edit = $MarginContainer/RequestFormContainer/HBoxContainer3/VBoxLineEdits/NameLineEdit
@onready var pwd_code_line_edit = $MarginContainer/PwdResetFormContainer/HBoxContainer3/VBoxLineEdits/CodeLineEdit
@onready var pwd_password_line_edit = $MarginContainer/PwdResetFormContainer/HBoxContainer3/VBoxLineEdits/PasswordLineEdit
@onready var pwd_confirm_pass_line_edit = $MarginContainer/PwdResetFormContainer/HBoxContainer3/VBoxLineEdits/ConfirmPassLineEdit
@onready var button_audio_player = %ButtonAudioPlayer
@onready var wait_timer = %WaitTimer
@onready var anti_click_panel = %AntiClickPanel

@export var rf_interactive_items_collection: Array[Control]
@export var rf_text_for_interactive_items: Array[String]
@export var pwdrf_interactive_items_collection: Array[Control]
@export var pwdrf_text_for_interactive_items: Array[String]
@export var pc_interactive_items_collection: Array[Control]
@export var pc_text_for_interactive_items: Array[String]

signal play_button_sound()
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
signal send_only_announcement(announcement: String)
signal send_scene_for_signals(scene)

# Called when the node enters the scene tree for the first time.
func _ready():
	pwd_reset_form_container.hide()
	password_changed_container.hide()
	request_form_container.show()
	send_interactive_items.emit(rf_interactive_items_collection,rf_text_for_interactive_items,ANNOUNCEMENT)
	SilentWolf.Auth.sw_request_password_reset_complete.connect(_on_send_code_complete)
	SilentWolf.Auth.sw_reset_password_complete.connect(_on_reset_complete)
	close_button.pressed.connect(_on_closeButton_pressed)
	back_button.pressed.connect(_on_backButton_pressed)
	rf_submit_button.pressed.connect(_on_rf_submitButton_pressed)
	pwd_submit_button.pressed.connect(_on_pwd_submitButton_pressed)
	play_button_sound.connect(_on_button_play_sound)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	if "login_scene" in SilentWolf.Auth:
		login_scene = SilentWolf.Auth.login_scene

func _on_backButton_pressed() -> void:
	send_only_announcement.emit("Returning to main menu")
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(login_scene)

func _on_closeButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(login_scene)

func _on_send_code_complete(sw_result: Dictionary) -> void:
	anti_click_panel.hide()
	if sw_result.success:
		send_code_success()
	else:
		send_code_failure(sw_result.error)

func _on_rf_submitButton_pressed() -> void:
	play_button_sound.emit()
	player_name = rf_name_line_edit.text
	anti_click_panel.show()
	SilentWolf.Auth.request_player_password_reset(player_name)
	_show_rf_info(tr(PROCESSING))

func _on_pwd_submitButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	var code = pwd_code_line_edit.text
	var password = pwd_password_line_edit.text
	var confirm_password = pwd_confirm_pass_line_edit.text
	SilentWolf.Auth.reset_player_password(player_name, code, password, confirm_password)
	_show_pwdrf_info(tr(PROCESSING))

func send_code_success() -> void:
	request_form_info_label.hide()
	request_form_container.hide()
	pwd_reset_form_container.show()
	send_interactive_items.emit(pwdrf_interactive_items_collection,pwdrf_text_for_interactive_items,"Authentication Successfull") #NOT TRANSLATED YET

func send_code_failure(error: String) -> void:
	_show_rf_info(tr(CODE_CANT_SEND) + str(error),RED)
	
func _on_reset_complete(sw_result: Dictionary) -> void:
	anti_click_panel.hide()
	if sw_result.success:
		reset_success()
	else:
		reset_failure(sw_result.error)

func reset_success() -> void:
	_hide_pwdrf_info()
	pwd_reset_form_container.hide()
	password_changed_container.show()
	send_interactive_items.emit(pc_interactive_items_collection,pc_text_for_interactive_items,"Password reset succesfully") #NOT TRANSLATED YET

func reset_failure(error: String) -> void:
	_show_pwdrf_info(tr(PASS_CANT_RESET) + str(error), RED)

func _show_pwdrf_info(text: String, colr: Color = WHITE) -> void:
	pwd_reset_info_label.text = text
	pwd_reset_info_label.set("theme_override_colors/font_color",colr)
	pwd_reset_info_label.show()
	send_only_announcement.emit(text)

func _hide_pwdrf_info() -> void:
	pwd_reset_info_label.hide()

func _show_rf_info(text: String, colr: Color = WHITE) -> void:
	request_form_info_label.text = text
	request_form_info_label.set("theme_override_colors/font_color",colr)
	request_form_info_label.show()
	send_only_announcement.emit(text)

func _hide_rf_info() -> void:
	request_form_info_label.hide()

func _on_button_play_sound() -> void:
	button_audio_player.play()

func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
