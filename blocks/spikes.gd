extends Area2D

@export var up = false

func _ready():
	if up:
		$AnimationPlayer.play("rise")

func rise(body):
	if !up:
		$AnimationPlayer.play("rise")
		up = true
func lower(body):
	if up:
		$AnimationPlayer.play("lower")
		up = false
