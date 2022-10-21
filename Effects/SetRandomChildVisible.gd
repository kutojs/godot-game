extends Node2D


func _ready():
	for child in get_children():
		child.hide()
	get_child(randi()%get_child_count()).show()
	global_rotation = rand_range(0.0, 2*PI)
	scale = Vector2.ONE * rand_range(0.8, 1.0)
