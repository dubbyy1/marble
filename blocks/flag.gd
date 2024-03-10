extends Area2D

func _on_flag_area_entered(area):
	if not area.get_parent().get_node("goal/collision").disabled:
		$red.emitting = true
		$blue.emitting = true
		$green.emitting = true
