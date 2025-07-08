extends Control

const SWLogger = preload("res://addons/silent_wolf/utils/SWLogger.gd")
const RED = Color(1.0,0.0,0.0,1.0)
const WHITE = Color(1.0,1.0,1.0,1.0)
const PROCESSING = "PROCESSING"

@onready var info_label = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer/InfoLabel
@onready var submit_button = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer2/SubmitButton
@onready var resend_button = $MarginContainer/VBoxContainer/HBoxContainer5/VBoxContainer2/ResendButton
@onready var code_line_edit = $MarginContainer/VBoxContainer/HBoxContainer3/VBoxLineEdits/CodeLineEdit
@onready var wait_timer = %WaitTimer
@onready var button_audio_player = %ButtonAudioPlayer
@onready var anti_click_panel = %AntiClickPanel

signal play_button_sound()

func _ready():
	SilentWolf.Auth.sw_email_verif_complete.connect(_on_confirmation_complete)
	SilentWolf.Auth.sw_resend_conf_code_complete.connect(_on_resend_code_complete)
	submit_button.pressed.connect(_on_submitButton_pressed)
	resend_button.pressed.connect(_on_resendButton_pressed)
	play_button_sound.connect(_on_button_play_sound)

func _on_confirmation_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		confirmation_success()
	else:
		confirmation_failure(sw_result.error)

func confirmation_success() -> void:
	anti_click_panel.hide()
	SWLogger.info("email verification succeeded: " + str(SilentWolf.Auth.logged_in_player))
	# redirect to configured scene (user is logged in after registration)
	var scene_name = SilentWolf.auth_config.redirect_to_scene
	get_tree().change_scene_to_file(scene_name)

func confirmation_failure(error: String) -> void:
	_hide_infolabel()
	anti_click_panel.hide()
	SWLogger.info("email verification failed: " + str(error))
	_show_infoLabel(error, RED)

func _on_resend_code_complete(sw_result: Dictionary) -> void:
	if sw_result.success:
		resend_code_success()
	else:
		resend_code_failure()

func resend_code_success() -> void:
	SWLogger.info("Code resend succeeded for player: " + str(SilentWolf.Auth.tmp_username))
	_show_infoLabel("Confirmation code was resent to your email address. Please check your inbox (and your spam).", RED)

func resend_code_failure() -> void:
	SWLogger.info("Code resend failed for player: " + str(SilentWolf.Auth.tmp_username))
	_show_infoLabel("Confirmation code could not be resent", RED)

func _show_infoLabel(text: String, colr: Color = WHITE) -> void:
	info_label.text = text
	info_label.set("theme_override_colors/font_color",colr)
	info_label.show()

func _hide_infolabel() -> void:
	info_label.text = ""
	info_label.hide()

func _on_submitButton_pressed() -> void:
	play_button_sound.emit()
	anti_click_panel.show()
	var username = SilentWolf.Auth.tmp_username
	var code = code_line_edit.text
	SWLogger.debug("Email verification form submitted, code: " + str(code))
	SilentWolf.Auth.verify_email(username, code)
	_show_infoLabel(PROCESSING)

func _on_resendButton_pressed() -> void:
	play_button_sound.emit()
	var username = SilentWolf.Auth.tmp_username
	SWLogger.debug("Requesting confirmation code resend")
	SilentWolf.Auth.resend_conf_code(username)
	_show_infoLabel(PROCESSING)

func _on_button_play_sound() -> void:
	button_audio_player.play()

func _on_wait_timer_timout() -> void:
	anti_click_panel.hide()
