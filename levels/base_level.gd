extends Node2D

@export var current_level = "1-1"
@export var next_level = "1-2"
var over = true

@onready var flag_pos = $blocks/flag/pos.global_position
var game_mode = "normal"
var ghost_pos = []
var gp_index = 0
var time = 0.0

func _ready():
	$ghost.texture = $player/sprite.texture
	
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	$canvas/level.text = current_level
	next_level = "res://levels/" + next_level + ".tscn"
	current_level = "res://levels/" + current_level + ".tscn"
	
	$canvas/cover.visible = true
	$canvas/timer.visible = false
	$canvas/time_attack.visible = false
	
	if FileAccess.file_exists("user://save.json"):
		var save = FileAccess.open("user://save.json", FileAccess.READ_WRITE)
		var save_str = save.get_as_text()
		save_str = JSON.parse_string(save_str)
		game_mode = save_str["game_mode"]
		$player.change_skin("res://sprites/skins/" + save_str["skin"])
		save.close()
	if game_mode == "time_attack":
		$canvas/timer.visible = true
		$canvas/time_attack.visible = true
		
		if FileAccess.file_exists("user://times.json"):
			var timeF = FileAccess.open("user://times.json", FileAccess.READ_WRITE)
			var time_str = timeF.get_as_text()
			timeF.close()
			if name in time_str:
				time_str = JSON.parse_string(time_str)
				ghost_pos = time_str[name]
				$canvas/time_attack.text = str(snapped(ghost_pos[-1], 0.01))

func _process(delta):
	process()

func process():
	$bg.global_position.x = snapped($player.global_position.x - 500, 24)
	$bg.global_position.y = snapped($player.global_position.y - 500, 24)

func _physics_process(_delta):
	time = $canvas/timer.time
	$player.level_time = time
	if over:
		$canvas/timer.started = false
	elif $player.started:
		$canvas/timer.started = true
		time = $canvas/timer.time
	if ghost_pos != [] and not over and $player.started:
		$canvas/timer.started = true
		if game_mode == "time_attack":
			if $canvas/timer.time < ghost_pos[-1]:
				$canvas/timer.self_modulate = Color(0.2, 1, 0.2)
			else:
				$canvas/timer.self_modulate = Color(1, 0.2, 0.2)
		$ghost.visible = true
		if gp_index < len(ghost_pos) - 1:
			var ggp = $ghost.global_position
			var new_ggp = Vector2(ghost_pos[gp_index][0], ghost_pos[gp_index][1])
			if gp_index > 0:
				$ghost.rotation_degrees += ggp.distance_to(new_ggp) * 5
			$ghost.global_position = new_ggp
			gp_index += 1

func finish():
	$animations.play("close")
	$player.stop()
	over = true
func reset():
	$animations.play("reset")
	$player.stop()
	over = true

func _on_animations_animation_finished(anim_name):
	if anim_name == "open":
		$player.play()
	if anim_name == "close":
		if game_mode == "time_attack" and not "0-" in next_level:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_level)
	if anim_name == "reset":
		get_tree().reload_current_scene()

func _on_start_timeout():
	over = false

func _on_menu_pressed():
	next_level = "res://levels/0-0.tscn"
	finish()
