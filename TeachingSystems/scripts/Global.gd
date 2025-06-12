extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	SilentWolf.configure({
	"api_key": "CqSf9SKaX69546wWGLUXHaw3ngFl5L9P2vJvu9me",
	"game_id": "multiplicationteachingsystem",
	"log_level": 1
	})

	SilentWolf.configure_scores({"open_scene_on_close": "res://scenes/StageMenu.tscn"})
	
	SilentWolf.configure_auth({
		"redirect_to_scene": "res://scenes/StageMenu.tscn",
		"login_scene": "res://addons/silent_wolf/Auth/Login.tscn",
		"reset_password_scene": "res://scenes/resetpass_scene.tscn",
		"email_confirmation_scene": "res://scenes/confirmmail_scene.tscn",
		"session_duration_second": 0,
		"saved_session_expiration_days": 30
	})
