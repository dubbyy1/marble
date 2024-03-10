extends Label

var time = 0.0
var first = true
var started = false

func _physics_process(delta):
	if first:
		first = false
	else:
		if not get_node("/root").get_child(2).over and started:
			time += delta
		var time_str = str(snapped(time, 0.01))
		if not "." in time_str:
			time_str += ".00"
		elif len(time_str.split(".")[1]) == 1:
			time_str += "0"
		text = time_str
