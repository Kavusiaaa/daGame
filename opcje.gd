extends Control


@onready var sfx_slider = $SFXContainer/SFXSlider
@onready var music_slider = $MusicContainer/MusicSlider
@onready var credits_button = $CreditsButton
@onready var credits_label = $CreditsText
@onready var close_button = $CloseButton

# ⚙️ parametry scrolla
var credits_speed = 50  # pikseli na sekundę
var credits_active = false

func _ready():
	# Sprawdzenie, czy node'y istnieją
	assert(sfx_slider != null, "Nie znaleziono SFXSlider! Sprawdź ścieżkę w @onready")
	assert(music_slider != null, "Nie znaleziono MusicSlider!")
	assert(credits_label != null, "Nie znaleziono CreditsLabel!")
	assert(credits_button != null, "Nie znaleziono CreditsButton!")
	assert(close_button != null, "Nie znaleziono CloseButton!")

	credits_label.visible = false
	credits_button.visible = true

	# ustawienie zakresów suwaków
	sfx_slider.min_value = -40
	sfx_slider.max_value = 0
	sfx_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

	music_slider.min_value = -40
	music_slider.max_value = 0
	music_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))

	# podłączenie sygnałów
	sfx_slider.connect("value_changed", Callable(self, "_on_sfx_slider_value_changed"))
	music_slider.connect("value_changed", Callable(self, "_on_music_slider_value_changed"))
	credits_button.connect("pressed", Callable(self, "_on_credits_button_pressed"))
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))


func _process(delta):
	if credits_active:
		credits_label.position.y -= credits_speed * delta
		if credits_label.position.y + credits_label.size.y < 0:
			credits_active = false
			credits_label.visible = false



func _on_sfx_slider_value_changed(value):
	var bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, value)

func _on_music_slider_value_changed(value):
	var bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, value)



func _on_credits_button_pressed():
	$ButtonClickSound.play()
	await $ButtonClickSound.finished
	$CreditsButton.visible = false
	credits_label.visible = true
	credits_label.position.y = get_viewport_rect().size.y  # start poza ekranem
	credits_active = true




func _on_close_button_button_down() -> void:
	pass # Replace with function body.


func _on_close_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
