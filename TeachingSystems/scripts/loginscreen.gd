extends Control

const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
const RED = Color(1.0,0.0,0.0,1.0)
const WHITE = Color(1.0,1.0,1.0,1.0)
const PROCESSING = "PROCESSING_TEXT"

@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer/InfoLabel
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer2/BackButton
@onready var forgot_password_link_button = $MarginContainer/VBoxContainer/HBoxContainer6/ForgotPassword_LinkButton
@onready var login_button = $MarginContainer/VBoxContainer/HBoxContainer5/LoginButton
@onready var v_box_line_edits = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxLineEdits
@onready var stay_signed_check_box = $MarginContainer/VBoxContainer/HBoxContainer7/StaySignedCheckBox
@onready var button_audio_player = %ButtonAudioPlayer
@onready var wait_timer = %WaitTimer
@onready var anti_click_panel = %AntiClickPanel

signal play_button_sound()

func _ready():
	SilentWolf.Auth.sw_login_complete.connect(_on_login_complete)
	back_button.pressed.connect(_on_back_button_pressed)
	forgot_password_link_button.pressed.connect(_on_forgotLinkButton_pressed)
	login_button.pressed.connect(_on_login_button_pressed)
	play_button_sound.connect(_on_button_play_sound)
	wait_timer.timeout.connect(_on_wait_timer_timout)
	stay_signed_check_box.pressed.connect(_on_stay_signed_in_check_button_pressed)

func _on_login_complete(sw_result: Dictionary) -> void:
	anti_click_panel.hide()
	if sw_result.success:
		login_success()
	else:
		login_failure(sw_result.error)
		
func login_success() -> void:
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	SWLogger.info("logged in as: " + str(SilentWolf.Auth.logged_in_player))
	get_tree().change_scene_to_file(scene_name)
	
func login_failure(error: String) -> void:
	_show_infolabel(error, true)
	SWLogger.info("log in failed: " + str(error))

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

func _on_forgotLinkButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(SilentWolf.auth_config.reset_password_scene)

func _on_back_button_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	wait_timer.start()
	await wait_timer.timeout
	get_tree().change_scene_to_file(SilentWolf.auth_config.redirect_to_scene)

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

func _on_button_play_sound() -> void:
	button_audio_player.play()

func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()

func _on_stay_signed_in_check_button_pressed() -> void:
	play_button_sound.emit()
