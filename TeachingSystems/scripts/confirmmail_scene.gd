extends Control
## This script is attached to the mail confirmation scene. After the user inputs their username,
## password and email, we need to make sure that the email exists, and so after sending a code to
## their email, the user needs to input that code here. It contains a resend function if the user
## is late, and also a submit button to finish the input.

## This constant contains a reference to the silent wolf logger script, which is used for debugging
## purposes. When there is a succesful resent of the code or the user input the code correctly
## we can use this to mark the occesion on the debugger
const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
## This constant contains the color red, used for messages
const RED = Color(1.0,0.0,0.0,1.0)
## This constant contains the color white, used for messages
const WHITE = Color(1.0,1.0,1.0,1.0)
## This constant contains code for the word processing, its translated later
const PROCESSING = "PROCESSING_TEXT"
## This constant contains code for the word confirmation resent, its translated later
const CONFIRMATION_RESENT = "CODE_RESENT_TEXT"
## This constant contains code for the word unable to resent code, its translated later
const CONFIRMATION_CANT_RESENT = "CODE_CANT_RESENT_TEXT"
## This constant contains the announcement for the tts when entering the scene, its not translated
const ANNOUNCEMENT: String = "In order for your account to be created you need to confirm your email address. Input the code that was sent to your email" #NOT TRANSLATED

## This variable contains a reference to the info label on the hierarchy
@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer/InfoLabel
## This variable contains a reference to the submit button on the hierarchy
@onready var submit_button = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer2/SubmitButton
## This variable contains a reference to the resend button on the hierarchy
@onready var resend_button = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer2/ResendButton
## This variable contains a reference to the code text box on the hierarchy
@onready var code_line_edit = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxLineEdits/CodeLineEdit
## This variable contains a reference to the wait timer on the hierarchy
@onready var wait_timer = %WaitTimer
## This variable contains a reference to the audio player for the button sound on the hierarchy
@onready var button_audio_player = %ButtonAudioPlayer
## This variable contains a reference to the code text box on the hierarchy
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
	SilentWolf.Auth.sw_email_verif_complete.connect(_on_confirmation_complete)
	SilentWolf.Auth.sw_resend_conf_code_complete.connect(_on_resend_code_complete)
	submit_button.pressed.connect(_on_submitButton_pressed)
	resend_button.pressed.connect(_on_resendButton_pressed)
	play_button_sound.connect(_on_button_play_sound)
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT)

## This function should be connected with the silent wolf email verification completion. It requires
## a dictionary item with the result that we can then use to determine the outcome
func _on_confirmation_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		confirmation_success()
	else:
		confirmation_failure(sw_result.error)

## This function is called when the user succesfully inputs the code we sent. We then need to send
## the user back at the main scene.
func confirmation_success() -> void:
	anti_click_panel.hide()
	SWLogger.info("email verification succeeded: " + str(SilentWolf.Auth.logged_in_player))
	# redirect to configured scene (user is logged in after registration)
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	get_tree().change_scene_to_file(scene_name)

## This function is called after the on confirmation complete determines that the code is false.
## We need to show the user that the code is wrong using the info label object by outputing
## the error given from the failure
func confirmation_failure(error: String) -> void:
	_hide_infolabel()
	anti_click_panel.hide()
	SWLogger.info("email verification failed: " + str(error))
	_show_infoLabel(error, RED)

## This function is called when the user wants us to resend the confirmation code. Using the 
## result dictionary we can determine the outcome and call the appropriate function
func _on_resend_code_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		resend_code_success()
	else:
		resend_code_failure()

## This function should be called when the confirmation code is resent succesfully using 
## the info label to show the outcome to the user.
func resend_code_success() -> void:
	SWLogger.info("Code resend succeeded for player: " + str(SilentWolf.Auth.tmp_username))
	_show_infoLabel(tr(CONFIRMATION_RESENT), RED)

## This function should be called when the confirmation code can't be resent using the
## info label to show the outcome to the user.
func resend_code_failure() -> void:
	SWLogger.info("Code resend failed for player: " + str(SilentWolf.Auth.tmp_username))
	_show_infoLabel(tr(CONFIRMATION_CANT_RESENT), RED)

## This function should be called when we need to notify the user of the result from their actions.
## With a string message and a color variable we show the appropriate label on the scene
## and fill the label with the message while also coloring it and then voicing the message
## by emitting the send only announcement signal
func _show_infoLabel(text: String, colr: Color = WHITE) -> void:
	info_label.text = tr(text)
	send_only_announcement.emit(text)
	info_label.set("theme_override_colors/font_color",colr)
	info_label.show()

## This function should be called when we want to hide any notification towards the user. We only
## need to clear the text and hide the info label
func _hide_infolabel() -> void:
	info_label.text = ""
	info_label.hide()

## This function should be connected to the submit button. After pressing the button we tkae the
## username from the registration along with the code sent to the user to verify it
func _on_submitButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	var username = SilentWolf.Auth.tmp_username
	var code = code_line_edit.text
	SWLogger.debug("Email verification form submitted, code: " + str(code))
	SilentWolf.Auth.verify_email(username, code)
	_show_infoLabel(tr(PROCESSING))

## This function should be connected to the resend code button. With this we can send another code
## to the user using their info.
func _on_resendButton_pressed() -> void:
	play_button_sound.emit()
	var username = SilentWolf.Auth.tmp_username
	SWLogger.debug("Requesting confirmation code resend")
	SilentWolf.Auth.resend_conf_code(username)
	_show_infoLabel(tr(PROCESSING))

## This function is used to play the audio file in the button audio player. Used with buttons.
func _on_button_play_sound() -> void:
	button_audio_player.play()

## This function is conected to the wait timer on the hierarchy. When we call the wait timer we
## enable the anti clicking panel so that the player cant press any more buttons. After the timer
## end we can hide the panel so that the player can continue.
func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
