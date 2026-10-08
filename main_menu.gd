extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PauseMenu.enter_title_menu()
	var start := $VBoxContainer/Start
	var options := $VBoxContainer/Opcje
	var exit := $VBoxContainer/Wyjscie
	for button in [start, options, exit]:
		button.custom_minimum_size = Vector2(500, 64)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
	start.focus_mode = Control.FOCUS_ALL
	start.grab_focus()


func _on_start_pressed():
	$VBoxContainer/Start.disabled = true
	get_tree().paused = false
	$ClickSound.play()
	await $ClickSound.finished
	var error := get_tree().change_scene_to_file("res://school.tscn")
	if error != OK:
		push_error("Could not open gameplay scene: res://school.tscn (error %s)" % error)

func _on_opcje_pressed(): #Gdy wciśnięto opcje
	$VBoxContainer/Opcje.disabled = true
	$ClickSound.play()
	await $ClickSound.finished
	var error := get_tree().change_scene_to_file("res://opcje.tscn")
	if error != OK:
		push_error("Could not open options scene: res://opcje.tscn (error %s)" % error)
	

func _on_wyjscie_pressed(): #Gdy wciśnięto wyjście
	$VBoxContainer/Wyjscie.disabled = true
	$AWP_Sound.play()
	await $AWP_Sound.finished
	get_tree().quit()
	
