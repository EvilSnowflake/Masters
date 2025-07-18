extends Control

const USERHELPMESSAGE: String = "USER_HELP_MESSAGE_TEXT"
const PASSHELPMESSAGE: String = "PASS_HELP_MESSAGE_TEXT"
const PROCESSING: String = "PROCESSING_TEXT"
const RED: Color = Color(1.0,0.0,0.0,1.0)
const WHITE: Color = Color(1.0,1.0,1.0,1.0)
const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")


@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer/InfoLabel
@onready var submit_button = $MarginContainer/VBoxContainer/HBoxContainer5/SubmitButton
@onready var v_box_labels = $MarginContainer/VBoxContainer/HBoxContainer3/VBox_Labels
@onready var v_box_line_edits = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxLineEdits
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer2/BackButton
@onready var username_tool_button = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/UsernameToolButton
@onready var password_tool_button = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/PasswordToolButton
@onready var button_audio_player = %ButtonAudioPlayer
@onready var wait_timer = %WaitTimer
@onready var anti_click_panel = %AntiClickPanel

signal play_button_sound()

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

func _on_registration_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		registration_success()
	else:
		registration_failure(sw_result.error)

func _on_registration_user_pwd_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		registration_user_pwd_success()
	else:
		registration_failure(sw_result.error)

func registration_success() -> void:
	# redirect to configured scene (user is logged in after registration)
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	# if doing email verification, open scene to confirm email address
	if ("email_confirmation_scene" in SilentWolf.auth_config) and (SilentWolf.auth_config.email_confirmation_scene) != "":
		SWLogger.info("registration succeeded, waiting for email verification...")
		scene_name = SilentWolf.auth_config.email_confirmation_scene
	else:
		SWLogger.info("registration succeeded, logged in player: " + str(SilentWolf.Auth.logged_in_player))
	get_tree().change_scene_to_file(scene_name)

func registration_user_pwd_success() -> void:
	anti_click_panel.hide()
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	get_tree().change_scene_to_file(scene_name)

func registration_failure(error: String) -> void:
	anti_click_panel.hide()
	_show_infolabel(error,true)

func _show_infolabel(text: String, isError = false) -> void:
	info_label.text =  text
	if isError:
		info_label.set("theme_override_colors/font_color",RED)
	else:
		info_label.set("theme_override_colors/font_color",WHITE)
	info_label.show()

func _hide_infolabel() -> void:
	info_label.text = ""
	info_label.hide()

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

func _on_submit_up_button_pressed() -> void:
	play_button_sound.emit()
	var children = v_box_line_edits.get_children()
	var player_name = children[0].text
	var password = children[2].text
	var confirm_password = children[3].text
	SilentWolf.Auth.register_player_user_password(player_name, password, confirm_password)
	_show_infolabel(tr(PROCESSING))

func _on_back_button_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(SilentWolf.auth_config.redirect_to_scene)

func _on_usernametoolbutton_mouse_entered() -> void:
	_show_infolabel(tr(USERHELPMESSAGE))

func _on_usernametoolbutton_mouse_exited() -> void:
	_hide_infolabel()

func _on_passwordtoolbutton_mouse_entered() -> void:
	_show_infolabel(tr(PASSHELPMESSAGE))

func _on_passwordtoolbutton_mouse_exited() -> void:
	_hide_infolabel()

func _on_button_play_sound() -> void:
	button_audio_player.play()

func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
