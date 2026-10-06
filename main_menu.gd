extends Control

func _ready() -> void:
	PauseMenu.enter_title_menu()


func _on_start_pressed():
	get_tree().paused = false
	$ClickSound.play()
	await $ClickSound.finished
	var error := get_tree().change_scene_to_file("res://school.tscn")
	if error != OK:
		push_error("Could not open gameplay scene: res://school.tscn (error %s)" % error)

func _on_opcje_pressed(): #Gdy wciśnięto opcje
	$ClickSound.play()
	await$ClickSound.finished
	get_tree().change_scene_to_file("res://opcje.tscn")
	

func _on_wyjscie_pressed(): #Gdy wciśnięto wyjście
	$AWP_Sound.play()
	await get_tree().create_timer($AWP_Sound.stream.get_length()).timeout
	get_tree().quit()
	
