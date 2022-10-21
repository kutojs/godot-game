extends Control



func _ready():
	$Button.connect("button_up", get_tree(), "quit")

func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
