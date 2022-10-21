extends Node2D


func _ready():
	hide()
	$ShowTimer.wait_time = rand_range(0.00001, 0.2)
	$ShowTimer.start()
	$SplatterSounds.play()
