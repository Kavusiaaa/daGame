extends Control

func _on_start_pressed(): #Gdy wciśnięto start
	$ClickSound.play()
	await$ClickSound.finished
	get_tree().change_scene_to_file("res://school.tscn")
	

func _on_opcje_pressed(): #Gdy wciśnięto opcje
	$ClickSound.play()
	await$ClickSound.finished
	get_tree().change_scene_to_file("res://opcje.tscn")
	

func _on_wyjscie_pressed(): #Gdy wciśnięto wyjście
	$AWP_Sound.play()
	await get_tree().create_timer($AWP_Sound.stream.get_length()).timeout
	print("Exit")
	
