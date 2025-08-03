extends Control
## Audio options belongs to a scene with the same name which shows Sliders for all audio buses.
## If the user changes any of the sliders and presses the save values, the number in the sliders
## is saved locally asa set of 3 percentage numbers, so that when the user opens the program
## again the values will return

const ANNOUNCEMENT = "Audio Options Menu. Here you can adjust the volume of the various buses with the appropriate sliders and then save them."

## This variable should hold the slider item for the master bus
@export var master_slider: HSlider
## This variable should hold the slider item for the sfx bus
@export var sfx_slider: HSlider
## This variable should hold the slider item for the music bus
@export var music_slider: HSlider
## This variable should hold the button that hides the audio options
@export var return_button: Button
## This variable should hold the button that saves the above sliders values
@export var save_button: Button
@export var interactive_items_collection: Array[Control]
@export var text_for_interactive_items: Array[String]

## This signal is called when the user presses the save button, it returns all the values
## from the sliders so that they can be saved
signal audio_values_changed(master: float, music: float, sfx: float)
## This signal is called when any button is pressed, it should be used for button sounds
signal on_button_pressed()
## This signal is called when the user changes any of the sliders, this should trigger a sound
signal sliders_value_change()
signal send_interactive_items(collection: Array[Control], text: Array[String], announcement: String)
signal send_only_announcement(announcement: String)

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

## This function only stop focusing on the slider when the user removes the mouse from it
func _on_master_slider_mouse_exited() -> void:
	release_focus()
## This function only stop focusing on the slider when the user removes the mouse from it
func _on_sfx_slider_mouse_exited() -> void:
	release_focus()
## This function only stop focusing on the slider when the user removes the mouse from it
func _on_music_slider_mouse_exited() -> void:
	release_focus()

## On slider values changed is connected to all the sliders in the scene so that they call 
## the sliders value change signal
func _on_slider_value_changed(_value: float) -> void:
	#send_only_announcement.emit("Slider changed to value: " + str(int(_value*100)) + " percent")
	sliders_value_change.emit()

## On return button pressed should be connected to the return button so that it hides the menu
func _on_return_button_pressed() -> void:
	on_button_pressed.emit()
	send_only_announcement.emit("Returning to main menu")
	self.hide()

## Initialiase values updates the sliders so that they show bus volume they are assigned to
func initialiase_values() -> void:
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(2))

## Load values takes 3 floats as inputs which then converts them to db in order to change
## the bus volume, the first input is for the master bus, the second is for the music
## and the third is for the sfx. Also it then calls the initialise values function to
## show the changes made
func load_values(master: float, music: float, sfx: float) -> void:
	#print_debug("loaded values : " + str(master) + ","+ str(music) + ","+ str(sfx))
	AudioServer.set_bus_volume_db(0, linear_to_db(master))
	AudioServer.set_bus_volume_db(1, linear_to_db(music))
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx))
	initialiase_values()

## On save button pressed is connected to the save button, it reads all the sliders values and then
## changes each bus accordingly, it then emits the audio values changed signal which saves
## the values found for future use.
func _on_save_button_pressed() -> void:
	on_button_pressed.emit()
	send_only_announcement.emit("Values saved, master slider " + str(int(master_slider.value * 100)) + ", music slider " + str(int(music_slider.value * 100)) + ", sound effects slider " + str(int(sfx_slider.value * 100)))
	var master_value = linear_to_db(master_slider.value)
	var music_value = linear_to_db(music_slider.value)
	var sfx_value = linear_to_db(sfx_slider.value)
	AudioServer.set_bus_volume_db(0, master_value)
	AudioServer.set_bus_volume_db(1, music_value)
	AudioServer.set_bus_volume_db(2, sfx_value)
	
	audio_values_changed.emit(master_slider.value, music_slider.value, sfx_slider.value)

func show_audio_menu() -> void:
	self.show()
	send_interactive_items.emit(interactive_items_collection,text_for_interactive_items,ANNOUNCEMENT+" Values are, master slider " + str(int(master_slider.value * 100)) + ", music slider " + str(int(music_slider.value * 100)) + ", sound effects slider " + str(int(sfx_slider.value * 100)))
