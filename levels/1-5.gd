extends "res://levels/base_level.gd"

func _on_player_detect_body_entered(body):
	if $player.global_position.x < 0:
		$blocks/flag.global_position.x = 288
		flag_pos = $blocks/flag/pos.global_position
	else:
		$blocks/flag.global_position.x = -288
		flag_pos = $blocks/flag/pos.global_position
