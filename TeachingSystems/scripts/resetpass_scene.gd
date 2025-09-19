extends Control
## This script should be attached to the reset password scene. There the user can input their name
## on the text box and then after receiving a code in their email they can submit the code
## here to authenticate their info. After that the user can change thei password to a new one.

const PROCESSING: String = "PROCESSING_TEXT"
const CODE_CANT_SEND: String = "CODE_CANT_SENT_TEXT"
const PASS_CANT_RESET: String = "PASS_CANT_RESET_TEXT"
const RED: Color = Color(1.0,0.0,0.0,1.0)
const WHITE: Color = Color(1.0,1.0,1.0,1.0)
const ANNOUNCEMENT: String = "Here you can reset your password. By writing your username and then inputing a code sent to your email you can then write a new password. You can move between input boxes with enter and not with the directional buttons" #NOT TRANSLATED

## This variable should be filled with the user's player name.
var player_name = null
## This variable contains a reference to the login scene.
var login_scene = "res://scenes/login_screen.tscn"

## This variable references the form container that takes an email code as an input and a new
## password
@onready var pwd_reset_form_container = $MarginContainer/BackButtonContainer/PwdResetFormContainer
## This variable references the form container that takes the user's name as input
@onready var request_form_container = $MarginContainer/BackButtonContainer/RequestFormContainer
## This variable references the form container that informs the user that they
## changed their password
@onready var password_changed_container = $MarginContainer/BackButtonContainer/PasswordChangedContainer
## This variable references the back button on the hierarchy
@onready var back_button = $MarginContainer/BackButtonContainer/HBoxContainer2/BackButton
## This variable references the password reset info label on the hierarchy
@onready var pwd_reset_info_label = $MarginContainer/BackButtonContainer/PwdResetFormContainer/HBoxContainer5/VBoxContainer/InfoLabel
## This variable references the request form info label on the hierarchy
@onready var request_form_info_label = $MarginContainer/BackButtonContainer/RequestFormContainer/HBoxContainer5/VBoxContainer/InfoLabel
## This variable references the close button on the hierarchy
@onready var close_button = $MarginContainer/BackButtonContainer/PasswordChangedContainer/HBoxContainer5/CloseButton
## This variable references the password submit button on the hierarchy
@onready var pwd_submit_button = $MarginContainer/BackButtonContainer/PwdResetFormContainer/HBoxContainer5/SubmitButton
## This variable references the request form submit button on the hierarchy
@onready var rf_submit_button = $MarginContainer/BackButtonContainer/RequestFormContainer/HBoxContainer5/SubmitButton
## This variable references the request form name text box on the hierarchy
@onready var rf_name_line_edit = $MarginContainer/BackButtonContainer/RequestFormContainer/HBoxContainer3/VBoxLineEdits/NameLineEdit
## This variable references the password code text box on the hierarchy
@onready var pwd_code_line_edit = $MarginContainer/BackButtonContainer/PwdResetFormContainer/HBoxContainer3/VBoxLineEdits/CodeLineEdit
## This variable references the password text box form the password form on the hierarchy
@onready var pwd_password_line_edit = $MarginContainer/BackButtonContainer/PwdResetFormContainer/HBoxContainer3/VBoxLineEdits/PasswordLineEdit
## This variable references the password confirm password text box on the hierarchy
@onready var pwd_confirm_pass_line_edit = $MarginContainer/BackButtonContainer/PwdResetFormContainer/HBoxContainer3/VBoxLineEdits/ConfirmPassLineEdit
## This variable references the audio player for button audio clip on the hierarchy
@onready var button_audio_player = %ButtonAudioPlayer
## This variable references the wait timer on the hierarchy
@onready var wait_timer = %WaitTimer
## This variable references the no click panel on the hierarchy
@onready var anti_click_panel = %AntiClickPanel

## This variable contains the items the request form needs to send to the tts component to be voiced
@export var rf_interactive_items_collection: Array[Control]
## This variable contains descriptions for the request form items send to the tts component
@export var rf_text_for_interactive_items: Array[String]
## This variable contains the items the password request form needs to send to the 
## tts component to be voiced
@export var pwdrf_interactive_items_collection: Array[Control]
## This variable contains descriptions for the password request form items send to the tts component
@export var pwdrf_text_for_interactive_items: Array[String]
## This variable contains the items the password changed request form needs to send to the tts 
## component to be voiced
@export var pc_interactive_items_collection: Array[Control]
## This variable contains descriptions for the password changed request form items send 
## to the tts component
@export var pc_text_for_interactive_items: Array[String]

## This signal should be emitted when the user presses a button, the appropriate audio clip
## should be played
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

## This function should be connected to the back button. It redirects the user to the
## login scene.
func _on_backButton_pressed() -> void:
	send_only_announcement.emit("Returning to main menu")
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(login_scene)

## This function should be connected to the close button. It redirects the user to the
## login scene.
func _on_closeButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(login_scene)

## This function should be called when the game attempts to send a code to the user's email.
## Depending on the input results it calls the success or failure function.
func _on_send_code_complete(sw_result: Dictionary) -> void:
	anti_click_panel.hide()
	if sw_result.success:
		send_code_success()
	else:
		send_code_failure(sw_result.error)

## This function should be connected to the request form submit button. It requests a password
## reset using the player's name text box.
func _on_rf_submitButton_pressed() -> void:
	play_button_sound.emit()
	player_name = rf_name_line_edit.text
	anti_click_panel.show()
	SilentWolf.Auth.request_player_password_reset(player_name)
	_show_rf_info(tr(PROCESSING))

## This function should be connected to the password reset form submit button. It reads the
## code, password and confirmed password text boxes in order to authenticate the user and 
## attempt to change their password.
func _on_pwd_submitButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	var code = pwd_code_line_edit.text
	var password = pwd_password_line_edit.text
	var confirm_password = pwd_confirm_pass_line_edit.text
	SilentWolf.Auth.reset_player_password(player_name, code, password, confirm_password)
	_show_pwdrf_info(tr(PROCESSING))

## This function should be called when the request code was successfuly sent to the user's
## email. It hades the request form info and container and show the password reset form.
func send_code_success() -> void:
	request_form_info_label.hide()
	request_form_container.hide()
	pwd_reset_form_container.show()
	send_interactive_items.emit(pwdrf_interactive_items_collection,
	pwdrf_text_for_interactive_items,"Authentication Successfull") #NOT TRANSLATED YET

## This function should be called when the program was unable to send a code for authentication.
func send_code_failure(error: String) -> void:
	_show_rf_info(tr(CODE_CANT_SEND) + str(error),RED)

## This function should be called when an attempt for a password reset was made. Depending on the
## result provided the appropriate function will be called.
func _on_reset_complete(sw_result: Dictionary) -> void:
	anti_click_panel.hide()
	if sw_result.success:
		reset_success()
	else:
		reset_failure(sw_result.error)

## This function should be called when reset attempt was successful. It shows the user
## that the password was reset while also notifying the user verbaly.
func reset_success() -> void:
	_hide_pwdrf_info()
	pwd_reset_form_container.hide()
	password_changed_container.show()
	send_interactive_items.emit(pc_interactive_items_collection,pc_text_for_interactive_items,
	"Password reset succesfully") #NOT TRANSLATED YET

## This function should be called when the password reset was unsuccesful. It notifyies the
## user that their password can't be reset along with thw eror inputed.
func reset_failure(error: String) -> void:
	_show_pwdrf_info(tr(PASS_CANT_RESET) + str(error), RED)

## This function should be used to show the user the password request form info label. It sets the
## text of the label as the input text and the color as the input color.
func _show_pwdrf_info(text: String, colr: Color = WHITE) -> void:
	pwd_reset_info_label.text = text
	pwd_reset_info_label.set("theme_override_colors/font_color",colr)
	pwd_reset_info_label.show()
	send_only_announcement.emit(text)

## This function should be called when we want to hide the password request form info label.
func _hide_pwdrf_info() -> void:
	pwd_reset_info_label.hide()

## This function should be used when we want to show the user the request form info label. It sets
## the text of the label and its text color as the input given.
func _show_rf_info(text: String, colr: Color = WHITE) -> void:
	request_form_info_label.text = text
	request_form_info_label.set("theme_override_colors/font_color",colr)
	request_form_info_label.show()
	send_only_announcement.emit(text)

## This function should be used when we want to hide the request form info label.
func _hide_rf_info() -> void:
	request_form_info_label.hide()

## This function should be called when a button is pressed. It plays and audio clip of a button
## being pressed.
func _on_button_play_sound() -> void:
	button_audio_player.play()

## This function should be connected to the wait timer. After counting down the timer hides the
## anti click panel so that the user can interact with the scene again.
func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
