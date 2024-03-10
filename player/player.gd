extends RigidBody2D

var press_start = 0
var start_rotation = -1
var press_length = 0

@onready var axis = $canvas/axis
@onready var corner = $canvas/corner

var finishing_level = false
var resetting = false

var jump = false
var can_jump = false

var started = false

var gravity = Vector2.ZERO
var stopped = true
var stop_point = Vector2(0, 0)
var stop_speed = Vector2(0, 0)
var resume = false
var sprite_color = Color(0, 0, 0)

var sensitivity = 50
var game_mode = "normal"

var recording = []
var level_time = 0.0
var deltaV = 0

var levels_completed = ""
var skin = "beta"

func _ready():
	axis.rotation_degrees = 0
	PhysicsServer2D.area_set_param(get_viewport().find_world_2d().get_space(),
	 PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2(0, 1))
	
	var user_dir = DirAccess.open("user://")
	if user_dir.file_exists("save.json"):
		var save = FileAccess.get_file_as_string("user://save.json")
		save = JSON.parse_string(save)
		skin = save["skin"]
		$sprite.texture = load("res://sprites/skins/" + save.skin)
		sensitivity = int(save["sensitivity"])
		game_mode = save["game_mode"]
		levels_completed = save["levels"]
	else:
		var save = FileAccess.open("user://save.json", FileAccess.WRITE_READ)
		save.store_string(Global.default_save)
		$sprite.texture = load("res://sprites/skins/marble_beta.png")
		save.close()
	
	#change_skin("res://sprites/skins/" + skin)

func _physics_process(delta):
	print(game_mode)
	
	deltaV = delta
	rotation_degrees = 0
	$flag_pointer.look_at(get_node("/root").get_child(2).flag_pos)
	
	if not get_parent().over:
		if Input.is_action_just_pressed("tap"):
			started = true
	if stopped or not started:
		global_position = stop_point
		$roll_1.volume_db = -80
		$roll_2.volume_db = -80
	if started and not stopped:
		roll() # sound and particles
		
		if Input.is_action_just_pressed("reset"):
			_on_kill_area_entered(self)
		if game_mode == "time_attack":
			recording.append([global_position.x, global_position.y])
		
		rotation_handling()
		
		jump_handling()

func rotation_handling(): # change gravity
	gravity = (axis.get_node("gravity").global_position - axis.global_position)
	gravity = gravity.normalized()
	PhysicsServer2D.area_set_param(get_viewport().find_world_2d().get_space(),
	 PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, gravity)
	$sprite.rotation_degrees += (linear_velocity.x / 10) * gravity.y

func jump_handling():
	var mouse_pos = corner.get_local_mouse_position().x - 160
	if Input.is_action_just_pressed("tap"):
		press_start = mouse_pos
	
	if Input.is_action_pressed("tap"):
		press_length += 1
		if abs(mouse_pos) > 0:
			if start_rotation == -1:
				start_rotation = axis.rotation_degrees
			var added_rotation = (((mouse_pos - press_start) / 320) * 360)
			added_rotation *= (float(sensitivity) / 50.0)
			axis.rotation_degrees = added_rotation + start_rotation
			$camera.rotation_degrees = axis.rotation_degrees
	
	if Input.is_action_just_released("tap"):
		start_rotation = -1
		if len($ground.get_overlapping_bodies()) > 0 and press_length <= 10:
			jump = true
		press_length = 0

func roll(): # sound and particles
	if len($ground.get_overlapping_bodies()) > 0: # sound and particles
		var total_speed = abs(linear_velocity.x) + abs(linear_velocity.y)
		var volume = (total_speed / 15) - 40
		volume = clamp(volume, -40, 6)
		$speed.text = str(total_speed, " | " + str(volume))
		$roll_1.volume_db = volume
		$roll_2.volume_db = volume + 5
	else:
		$roll_1.volume_db -= 2
		$roll_2.volume_db -= 2

func stop():
	stopped = true
	stop_point = global_position
	stop_speed = linear_velocity
func play():
	stopped = false
	resume = true

func change_skin(s):
	var res = load(s)
	sprite_color = res.get_image()
	sprite_color = sprite_color.get_pixelv(Vector2(11, 11))
	
	$flag_pointer/arrow.modulate = Color(sprite_color.r, sprite_color.g, sprite_color.b, 1)

func _integrate_forces(_state):
	angular_velocity = 0
	if stopped or not started:
		linear_velocity = Vector2.ZERO
	else:
		if jump:
			# 90 degrees
			#linear_velocity.x += -300 * (snapped(gravity.x + 1, 1) - 1) # 90 degrees
			#linear_velocity.y += -300 * (snapped(gravity.y + 1, 1) - 1) # 90 degrees
			
			# straight up
			linear_velocity.x += -300 * gravity.x
			linear_velocity.y += -300 * gravity.y
			jump = false
	if resume:
		linear_velocity = stop_speed
		resume = false

func _process(_delta):
	if finishing_level:
		gravity_scale = $next_level.time_left * 8
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, 0.1)
		if abs(linear_velocity.x) + abs(linear_velocity.y) < 2:
			get_node("/root").get_child(2).finish()
	if resetting:
		gravity_scale = $next_level.time_left * 8
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, 0.1)
		if abs(linear_velocity.x) + abs(linear_velocity.y) < 2:
			get_node("/root").get_child(2).reset() 
			resetting = false

func save():
		if not get_node("/root").get_child(2).name == "0-0":
			if game_mode == "time_attack":
				print("time attack game mode saivng")
				get_node("/root").get_child(2).over = true
				level_time += deltaV
				recording.append(level_time)
				if FileAccess.file_exists("user://times.json"):
					var times = FileAccess.open("user://times.json", FileAccess.READ)
					var times_str = times.get_as_text()
					times.close()
					
					var level = get_node("/root").get_child(2).name
					if level in times_str:
						times_str = JSON.parse_string(times_str)
						if times_str[level][-1] > level_time:
							times_str[level] = recording
							
							var new_times = ""
							for s in times_str:
								new_times += '"' + s + '" : ' + str(times_str[s]) + ', '
							new_times = "{" + new_times + "}"
							
							times = FileAccess.open("user://times.json", FileAccess.WRITE)
							times.store_string(new_times)
							times.close()
					else:
						var new_times = ""
						for i in range(len(times_str) - 1):
							new_times += times_str[i]
						new_times += '"' + level + '" : ' + str(recording) + ', }'
						times = FileAccess.open("user://times.json", FileAccess.WRITE)
						times.store_string(new_times)
						times.close()
				else:
					var level = get_node("/root").get_child(2).name
					var times = FileAccess.open("user://times.json", FileAccess.WRITE)
					times.store_string('{"' + level + '" : ' + str(recording) + ', ' + "}")
					times.close()
			elif not get_node("/root").get_child(2).name in levels_completed:
				var saveF = FileAccess.open("user://save.json", FileAccess.READ_WRITE)
				var save_str = saveF.get_as_text()
				saveF.close()
				save_str = JSON.parse_string(save_str)
				levels_completed += "," + str(get_node("/root").get_child(2).name)
				save_str["levels"] = levels_completed
				var new_save = ""
				for s in save_str:
					new_save += '"' + s + '" : "' + str(save_str[s]) + '", '
				new_save = "{" + new_save + "}"
				
				saveF = FileAccess.open("user://save.json", FileAccess.WRITE)
				saveF.store_string(new_save)
				saveF.close()
		elif get_node("/root").get_child(2).name == "0-0":
			var saveF = FileAccess.open("user://save.json", FileAccess.READ_WRITE)
			var save_str = saveF.get_as_text()
			saveF.close()
			save_str = JSON.parse_string(save_str)
			save_str["skin"] = skin
			print("Player save skin = " + skin)
			save_str["sensitivity"] = sensitivity
			save_str["game_mode"] = game_mode
			var new_save = ""
			for s in save_str:
				new_save += '"' + s + '" : "' + str(save_str[s]) + '", '
			new_save = "{" + new_save + "}"
			
			saveF = FileAccess.open("user://save.json", FileAccess.WRITE)
			saveF.store_string(new_save)
			saveF.close()

func _on_goal_area_entered(_area):
	if not $goal/collision.disabled:
		save()
		
		get_node("/root").get_child(2).over = true
		$collision.disabled = true
		$kill/collision.disabled = true
		$goal/collision.disabled = true
		finishing_level = true
		linear_velocity.y = -300 * gravity.y
func _on_kill_area_entered(_area):
	get_node("/root").get_child(2).over = true
	$collision.disabled = true
	$kill/collision.disabled = true
	$goal/collision.disabled = true
	$ground/collision.disabled = true
	collision_mask = 0
	
	resetting = true
	$death.process_material.set("color", sprite_color)
	$sprite.visible = false
	$flag_pointer/arrow.visible = false
	$death.emitting = true

func _on_player_body_entered(_body):
	can_jump = true
func _on_player_body_exited(_body):
	can_jump = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
