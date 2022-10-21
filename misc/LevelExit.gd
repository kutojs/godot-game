extends Area2D

func _ready():
	connect("body_entered", self, "on_body_enter")

func on_body_enter(body: PhysicsBody2D):
	if body.is_in_group("player"):
		LevelManager.load_next_level()
