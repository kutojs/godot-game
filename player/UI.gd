extends Node2D

onready var gun_ui = $GunUI
onready var health_ui = $HealthUI

var has_gun = false

func _process(delta):
	global_position = get_parent().get_camera_screen_center()

var ui_visible = false
func show_ui():
	if ui_visible:
		return
	ui_visible = true
	health_ui.show_ui()
	if has_gun:
		gun_ui.show_ui()
	$InvOpen.play()

func hide_ui():
	if !ui_visible:
		return
	ui_visible = false
	health_ui.hide_ui()
	if has_gun:
		gun_ui.hide_ui()
	$InvClose.play()

func spin_chamber(up: bool):
	gun_ui.spin_chamber(up)

func grab_item(pos: Vector2):
	health_ui.grab_item(pos)
	gun_ui.grab_item(pos)

func drag_item(pos: Vector2):
	health_ui.drag_item(pos)
	gun_ui.drag_item(pos)

func release_item(pos: Vector2):
	health_ui.release_item(pos)
	gun_ui.release_item(pos)
