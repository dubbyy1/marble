extends "res://levels/base_level.gd"

var scene = "main"
var skin = "beta"
var skin_index = 0
var skins = []
var sensitivity = 50
var levels = []

func get_skins():
	var skins = DirAccess.open("res://.godot/imported/").get_files()
	var s = []
	for file in skins:
		if "marble" in file and not "md5" in file:
			s.append(file.split("-")[0])
	return s

func get_save():
	var saveF = FileAccess.open("user://save.json", FileAccess.READ_WRITE)
	var save_str = saveF.get_as_text()
	saveF.close()
	var test_json_conv = JSON.new()
	test_json_conv.parse(save_str)
	save_str = test_json_conv.get_data()
	return save_str

func _ready():
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
		var test_json_conv = JSON.new()
		test_json_conv.parse(save_str)
		save_str = test_json_conv.get_data()
		game_mode = save_str["game_mode"]
		save.close()
	
	flag_pos = $play.global_position
	$player.game_mode = "normal"
	game_mode = "normal"
	for c in $canvas/blocks.get_children():
		c.visible = false
	
	skins = get_skins()
	skins.sort()
	
	var save = get_save()
	levels = save["levels"].split(",")
	for level in levels:
		var nl = Levels.levels[Levels.levels.find(level) + 1]
		next_level = "res://levels/" + nl + ".tscn"
	
	for level in Array(levels).slice(1):
		var NewButton = load("res://gui/level.tscn")
		var newButton = NewButton.instantiate()
		newButton.text = level
		newButton.connect("pressed", Callable(self, "select_level").bind(newButton.text))
		$canvas/blocks/level_select/grid.add_child(newButton)
	
	skin = save["skin"]
	$canvas/blocks/settings/sensitivity/sensitivity.value = int(save["sensitivity"])
	skin_index = skins.find(skin)
	$skin/sprite.texture = load("res://sprites/skins/" + skin)
	
	$player.change_skin("res://sprites/skins/" + skins[skin_index])
	$player.skin = skins[skin_index]

func _process(delta):
	process()
	if scene == "main":
		$skin.rotation_degrees += 0.3
		$settings.rotation_degrees -= 0.3
		
		$time_attack/sprite/red_hand.rotation_degrees += 1.5
		$time_attack/sprite/black_hand.rotation_degrees += 0.3

func finish():
	$animations.play("finish")
	$player.stop()
	over = true
	$player.save()

func _on_animations_animation_finished(anim_name):
	if anim_name == "close":
		for c in $canvas/blocks.get_children():
			c.visible = false
		$canvas/blocks.get_node(scene).visible = true
		$animations.play("open")
	if anim_name == "open":
		over = false
		if scene == "main":
			$player.play()
	if anim_name == "finish":
		get_tree().change_scene_to_file(next_level)
	if anim_name == "reset":
		get_tree().reload_current_scene()

func _on_back_pressed():
	scene = "main"
	for c in $canvas/blocks.get_children():
		c.visible = false
	$player.play()

func _on_skin_body_entered(body):
	scene = "skins"
	refresh_skins()
	for c in $canvas/blocks.get_children():
		c.visible = false
	$canvas/blocks.get_node(scene).visible = true
	$player.stop()
func _on_skins_right_pressed():
	skin_index += 1
	if skin_index == len(skins):
		skin_index = 0
	refresh_skins()
func _on_skins_left_pressed():
	skin_index -= 1
	if skin_index == -1:
		skin_index = len(skins) - 1
	refresh_skins()
func refresh_skins():
	$canvas/blocks/skins/marble_left.texture = load("res://sprites/skins/" + skins[skin_index - 1])
	$canvas/blocks/skins/marble_centre.texture = load("res://sprites/skins/" + skins[skin_index])
	if skin_index + 1 < len(skins):
		$canvas/blocks/skins/marble_right.texture = load("res://sprites/skins/" + skins[skin_index + 1])
	else:
		$canvas/blocks/skins/marble_right.texture = load("res://sprites/skins/" + skins[0])
	skin = skins[skin_index]
	var skinF = "res://sprites/skins/" + skin
	$skin/sprite.texture = load(skinF)
	$player/sprite.texture = load(skinF)
	$player.change_skin(skinF)
	$player.skin = skin

func _on_settings_body_entered(body):
	scene = "settings"
	for c in $canvas/blocks.get_children():
		c.visible = false
	$canvas/blocks.get_node(scene).visible = true
	$player.stop()
func _on_sensitivity_value_changed(value):
	$canvas/blocks/settings/sensitivity/value.text = str(value)
	$player.sensitivity = value
	sensitivity = value

func _on_time_attack_body_entered(body):
	game_mode = "time_attack"
	$player.game_mode = "time_attack"
	scene = "level_select"
	for c in $canvas/blocks.get_children():
		c.visible = false
	$canvas/blocks.get_node(scene).visible = true
	$player.stop()

func _on_play_body_entered(body):
	game_mode = "normal"
	$player.game_mode = "normal"
	finish()

func _on_level_select_body_entered(body):
	game_mode = "normal"
	$player.game_mode = "normal"
	scene = "level_select"
	for c in $canvas/blocks.get_children():
		c.visible = false
	$canvas/blocks.get_node(scene).visible = true
	$player.stop()
func select_level(l):
	next_level = "res://levels/" + l + ".tscn"
	finish()

func _on_practice_body_entered(body):
		get_tree().change_scene_to_file("res://levels/0-1.tscn")

func _on_delete_body_entered(body):
	scene = "delete"
	for c in $canvas/blocks.get_children():
		c.visible = false
	$canvas/blocks.get_node(scene).visible = true
	$player.stop()
func _on_confirm_delete_pressed():
	var save = DirAccess.open("user://")
	save.remove("times.json")
	save = FileAccess.open("user://save.json", FileAccess.WRITE)
	save.store_string(Global.default_save)
	
	get_tree().reload_current_scene()
func _on_cancel_delete_pressed():
	_on_back_pressed()
