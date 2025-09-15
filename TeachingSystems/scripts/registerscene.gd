extends Control
## This script should be attached to the register scene, there the user can create an account using
## a username, a password and their email. After filling their information and submiting, the user
## is redirected to the cofirm email scene.

const USERHELPMESSAGE: String = "USER_HELP_MESSAGE_TEXT"
const PASSHELPMESSAGE: String = "PASS_HELP_MESSAGE_TEXT"
const PROCESSING: String = "PROCESSING_TEXT"
const RED: Color = Color(1.0,0.0,0.0,1.0)
const WHITE: Color = Color(1.0,1.0,1.0,1.0)
const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
const ANNOUNCEMENT: String = "Register an account here to upload your saved data on the cloud. You can move between input boxes with enter and not with the directional buttons" #NOT TRANSLATED

## This variable should contain all the control object on the hierarchy the user can interact with.
## It will be sent to the tts component
@export var interactive_items_collection: Array[Control]
## This variable should contain test descriptions for the interactive items collection.
@export var text_for_interactive_items: Array[String]

## This variable references the info label on the hierarchy
@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer/InfoLabel
## This variable references the submit button on the hierarchy
@onready var submit_button = $MarginContainer/VBoxContainer/HBoxContainer5/SubmitButton
## This variable references the container box for labels on the hierarchy
@onready var v_box_labels = $MarginContainer/VBoxContainer/HBoxContainer3/VBox_Labels
## This variable references the container box for text boxes on the hierarchy
@onready var v_box_line_edits = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxLineEdits
## This variable references the back button on the hierarchy
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer2/BackButton
## This variable references the info box for the username on the hierarchy
@onready var username_tool_button = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/UsernameToolButton
## This variable references the info box for the password on the hierarchy
@onready var password_tool_button = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/PasswordToolButton
## This variable references the audio player for buttons on the hierarchy
@onready var button_audio_player = %ButtonAudioPlayer
## This variable references the wait timer on the hierarchy
@onready var wait_timer = %WaitTimer
## This variable references the no click panel on the hierarchy
@onready var anti_click_panel = %AntiClickPanel

## This signal should be emitted when a button is pressed so the appropriate sound is played
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
	SilentWolf.check_auth_ready()
	SilentWolf.Auth.sw_registration_complete.connect(_on_registration_complete)
	SilentWolf.Auth.sw_registration_user_pwd_complete.connect(_on_registration_user_pwd_complete)
	submit_button.pressed.connect(_on_submit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	username_tool_button.mouse_entered.connect(_on_usernametoolbutton_mouse_entered)
	username_tool_button.mouse_exited.connect(_on_usernametoolbutton_mouse_exited)
	password_tool_button.mouse_entered.connect(_on_passwordtoolbutton_mouse_entered)
	password_tool_button.mouse_exited.connect(_on_passwordtoolbutton_mouse_exited)
	play_button_sound.connect(_on_button_play_sound)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT)

## This function should be called when the user attempts to register with an email.
## Depending on the result given the process either calls the success or failure function.
## It also sends the user to the email authentication scene
func _on_registration_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		registration_success()
	else:
		registration_failure(sw_result.error)

## This function should be called when the user attempts to register without an email.
## Depending on the result given the process either calls the success or failure function
func _on_registration_user_pwd_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		registration_user_pwd_success()
	else:
		registration_failure(sw_result.error)

## This function should be called after a successful attempt at registration using an email
## It sends the user to the email authentication scene.
func registration_success() -> void:
	# redirect to configured scene (user is logged in after registration)
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	# if doing email verification, open scene to confirm email address
	if (("email_confirmation_scene" in SilentWolf.auth_config) and
	 (SilentWolf.auth_config.email_confirmation_scene) != ""):
		SWLogger.info("registration succeeded, waiting for email verification...")
		scene_name = SilentWolf.auth_config.email_confirmation_scene
	else:
		SWLogger.info("registration succeeded, logged in player: " + str(SilentWolf.Auth.logged_in_player))
	get_tree().change_scene_to_file(scene_name)

## This function should be called after a successful registration attempt without using an email.
## It sends the user to the main menu
func registration_user_pwd_success() -> void:
	anti_click_panel.hide()
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	get_tree().change_scene_to_file(scene_name)

## This function should be called after a failed attempt at registration. It iforms the
## user of the failure and lets them try again.
func registration_failure(error: String) -> void:
	anti_click_panel.hide()
	_show_infolabel(error,true)

## This function should be used to inform the user of any information related to their
## actions. It takes a text as input and show the info label filled with that text while
## also changing the text's color depending on if the information is an error or no.
func _show_infolabel(text: String, isError = false) -> void:
	info_label.text =  text
	send_only_announcement.emit(text)
	if isError:
		info_label.set("theme_override_colors/font_color",RED)
	else:
		info_label.set("theme_override_colors/font_color",WHITE)
	info_label.show()

## This function should be called when we want to clear and hide the info label.
func _hide_infolabel() -> void:
	info_label.text = ""
	info_label.hide()

## This function should be connected to the submit button. It takes all the info
## given by the user on all text boxes and uses them to to attempt to register the user
## through silent wolf.
func _on_submit_button_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	var children = v_box_line_edits.get_children()
	var player_name = children[0].text
	var email = children[1].text
	var password = children[2].text
	var confirm_password = children[3].text
	SilentWolf.Auth.register_player(player_name, email, password, confirm_password)
	_show_infolabel(tr(PROCESSING))

## This function can be used instead of submit button pressed, so that it can be called 
## when the button is let instead of just pressed.
func _on_submit_up_button_pressed() -> void:
	play_button_sound.emit()
	var children = v_box_line_edits.get_children()
	var player_name = children[0].text
	var password = children[2].text
	var confirm_password = children[3].text
	SilentWolf.Auth.register_player_user_password(player_name, password, confirm_password)
	_show_infolabel(tr(PROCESSING))

## This function should be connected to the back button. After a bit of time it redirects
## the user to the main menu.
func _on_back_button_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(SilentWolf.auth_config.redirect_to_scene)

## This function should be connected to the username tool button. When the user enters
## the button with their mouse it displays a help message for the username using the
## info label.
func _on_usernametoolbutton_mouse_entered() -> void:
	_show_infolabel(tr(USERHELPMESSAGE))

## This function should be connected to the username tool button. When the user exits
## the button with their mouse it hides the help message for the username.
func _on_usernametoolbutton_mouse_exited() -> void:
	_hide_infolabel()

## This function should be connected to the password tool button. When the user enters
## the button with their mouse it displays a help message for the password using the
## info label.
func _on_passwordtoolbutton_mouse_entered() -> void:
	_show_infolabel(tr(PASSHELPMESSAGE))

## This function should be connected to the password tool button. When the user exits
## the button with their mouse it hides the help message for the password.
func _on_passwordtoolbutton_mouse_exited() -> void:
	_hide_infolabel()

## This function should be called when a button is pressed to sound an appropriate audio clip.
func _on_button_play_sound() -> void:
	button_audio_player.play()

## This function should be connected to the wait timer. After finishing countdown it hides
## the no click panel so that the user can then interact with the scene.
func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
