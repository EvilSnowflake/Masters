extends Control


@export var master_slider: HSlider
@export var sfx_slider: HSlider
@export var music_slider: HSlider
@export var return_button: Button
@export var save_button: Button

signal audio_values_changed(master: float, music: float, sfx: float)
signal on_button_pressed()
signal sliders_value_change()

func _ready():
	initialiase_values()
	
	master_slider.mouse_exited.connect(_on_master_slider_mouse_exited)
	master_slider.value_changed.connect(_on_slider_value_changed)
	music_slider.mouse_exited.connect(_on_music_slider_mouse_exited)
	music_slider.value_changed.connect(_on_slider_value_changed)
	sfx_slider.mouse_exited.connect(_on_sfx_slider_mouse_exited)
	sfx_slider.value_changed.connect(_on_slider_value_changed)
	
	
	return_button.pressed.connect(_on_return_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
func _on_master_slider_mouse_exited():
	release_focus()
func _on_sfx_slider_mouse_exited():
	release_focus()
func _on_music_slider_mouse_exited():
	release_focus()
	
func _on_slider_value_changed(_value: float):
	sliders_value_change.emit()

func _on_return_button_pressed():
	on_button_pressed.emit()
	self.hide()

func initialiase_values():
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))

func load_values(master: float, music: float, sfx: float):
	print_debug("loaded values : " + str(master) + ","+ str(music) + ","+ str(sfx))
	
	AudioServer.set_bus_volume_db(0, linear_to_db(master))
	AudioServer.set_bus_volume_db(1, linear_to_db(music))
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx))
	initialiase_values()

func _on_save_button_pressed():
	on_button_pressed.emit()
	var master_value = linear_to_db(master_slider.value)
	var music_value = linear_to_db(music_slider.value)
	var sfx_value = linear_to_db(sfx_slider.value)
	AudioServer.set_bus_volume_db(0, master_value)
	AudioServer.set_bus_volume_db(1, music_value)
	AudioServer.set_bus_volume_db(2, sfx_value)
	
	audio_values_changed.emit(master_slider.value, music_slider.value, sfx_slider.value)
