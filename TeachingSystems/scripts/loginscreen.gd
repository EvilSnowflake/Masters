extends Control
## This script functions as a way for the user to log in to their registered account or
## change their password if they had forgot it.

const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
const RED = Color(1.0,0.0,0.0,1.0)
const WHITE = Color(1.0,1.0,1.0,1.0)
const PROCESSING = "PROCESSING_TEXT"
const ANNOUNCEMENT: String = "Here you can login to your account. You can move between input boxes with enter and not with the directional buttons" #NOT TRANSLATED

## This variable contains a referece for the info label on the hierarchy
@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer/InfoLabel
## This variable contains a referece for the back button on the hierarchy
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer2/BackButton
## This variable contains a referece for the forgot password link button on the hierarchy
@onready var forgot_password_link_button = $MarginContainer/VBoxContainer/HBoxContainer6/ForgotPassword_LinkButton
## This variable contains a referece for the login button on the hierarchy
@onready var login_button = $MarginContainer/VBoxContainer/HBoxContainer5/LoginButton
## This variable contains a referece for the box container for the text boxes on the hierarchy
@onready var v_box_line_edits = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxLineEdits
## This variable contains a referece for the stay signed in check box on the hierarchy
@onready var stay_signed_check_box = $MarginContainer/VBoxContainer/HBoxContainer7/StaySignedCheckBox
## This variable contains a referece for the audio player for the button sound on the hierarchy
@onready var button_audio_player = %ButtonAudioPlayer
## This variable contains a referece for the wait timer on the hierarchy
@onready var wait_timer = %WaitTimer
## This variable contains a referece for the no click panel on the hierarchy
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
	SilentWolf.Auth.sw_login_complete.connect(_on_login_complete)
	back_button.pressed.connect(_on_back_button_pressed)
	forgot_password_link_button.pressed.connect(_on_forgotLinkButton_pressed)
	login_button.pressed.connect(_on_login_button_pressed)
	play_button_sound.connect(_on_button_play_sound)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	stay_signed_check_box.pressed.connect(_on_stay_signed_in_check_button_pressed)
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT)

## This function should be called after the player tries to login to their account. It should
## receive a result for the action and def=pending on the result we call the appropriate function
func _on_login_complete(sw_result: Dictionary) -> void:
	anti_click_panel.hide()
	if sw_result.success:
		login_success()
	else:
		login_failure(sw_result.error)

## This function should be called if the result of the login attempt is a success. The user
## should be redirected to the main menu with the appropriate information of the account
func login_success() -> void:
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	SWLogger.info("logged in as: " + str(SilentWolf.Auth.logged_in_player))
	get_tree().change_scene_to_file(scene_name)

## This function should be calles if the result of the login attempt is a failure. We should
## inform the user of the failed attempt
func login_failure(error: String) -> void:
	_show_infolabel(error, true)
	SWLogger.info("log in failed: " + str(error))

## This function handles the info label that shows the user what is the result of their actions.
## It receives a text item and a bool for if the information is an error and then shows 
## the info label with the appriopriate color and then sends the text to be voiced in the tts
## component.
func _show_infolabel(text: String, isError = false) -> void:
	info_label.text =  text
	if isError:
		info_label.set("theme_override_colors/font_color",RED)
	else:
		info_label.set("theme_override_colors/font_color",WHITE)
	info_label.show()
	send_only_announcement.emit(text)

## This function should be used to clear and hide the info label.
func _hide_infolabel() -> void:
	info_label.text = ""
	info_label.hide()

## This function should be connected to the forgot password button. It redirects the user
## to the forgot password scene.
func _on_forgotLinkButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(SilentWolf.auth_config.reset_password_scene)

## This function should be connected to the back button. It redirects the user to
## the main menu
func _on_back_button_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(SilentWolf.auth_config.redirect_to_scene)

## This function should be connected to the login button. Using the data from the textboxes above
## it tries to authenticate the user and then log them into the account.
func _on_login_button_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	var children = v_box_line_edits.get_children()
	var username = children[0].text
	var password = children[1].text
	var remember_me = stay_signed_check_box.is_pressed()
	SWLogger.debug("Login form submitted, remember_me: " + str(remember_me))
	SilentWolf.Auth.login_player(username, password, remember_me)
	_show_infolabel(tr(PROCESSING))

## This function should be used when the user presses a button to play the appropriate sound.
func _on_button_play_sound() -> void:
	button_audio_player.play()

## This function should be connected to the wait timer. When the anti click panel appears
## so that the user can't interact with the scene, the timer should start and then 
## after the timer ends it informs the scene to hide the anti click panel.
func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()

## This function should be connected to the stay signed in checkbox. It plays a button sound.
func _on_stay_signed_in_check_button_pressed() -> void:
	play_button_sound.emit()
