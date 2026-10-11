extends TextureRect

@export var textures: Array[Texture2D] = []
var current_index: int = 0
var timer: float = 0.0

func _process(delta: float):
	if textures.is_empty():
		return
		
	timer += delta
	if timer >= 1.0: # Co każdą sekundę
		timer = 0.0
		current_index = (current_index + 1) % textures.size()
		texture = textures[current_index]
