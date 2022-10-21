extends Node2D

export var stop_all_on_play = false
func play():
	if stop_all_on_play:
		stop()
	get_child(randi()%get_child_count()).play()

func is_playing():
	for child in get_children():
		if child.is_playing():
			return true
	return false

func stop():
	for child in get_children():
		child.stop()
