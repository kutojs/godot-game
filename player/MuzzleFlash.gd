extends Node2D


func _ready():
	hide_all()
	$Timer.connect("timeout", self, "hide_all")
	$StopSmokeTimer.connect("timeout", self, "stop_smoke")

func hide_all():
	for s in $Sprites.get_children():
		s.hide()

func stop_smoke():
	$SmokeTrail.emitting=false

func flash():
	$Particles2D.restart()
	$SmokeTrail.emitting=true
	hide_all()
	$Sprites.get_child(randi() % $Sprites.get_child_count()).show()
	$Timer.start()
	$StopSmokeTimer.start()
