extends Node2D

var gravity = 98
var velo = 0

var spin_speed = 400
func _ready():
	spin_speed = rand_range(-spin_speed, spin_speed)

func _physics_process(delta):
	velo += gravity * delta
	translate(Vector2.DOWN * velo)
	rotate(deg2rad(spin_speed*delta))
	if global_position.y > 5000:
		queue_free()
