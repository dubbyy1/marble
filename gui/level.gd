extends Button

func _ready():
	if text[0] == "1":
		$TextureRect.self_modulate = Color(1, 0.2, 0.2)
	elif text[0] == "2":
		$TextureRect.self_modulate = Color(1, 1, 0.2)
	elif text[0] == "3":
		$TextureRect.self_modulate = Color(0.2, 1, 0.2)
	elif text[0] == "4":
		$TextureRect.self_modulate = Color(0.2, 1, 1)
	elif text[0] == "5":
		$TextureRect.self_modulate = Color(0.2, 0.2, 1)
