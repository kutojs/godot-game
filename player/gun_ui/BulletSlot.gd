extends PhysicsBody2D

class_name BulletSlot

onready var bullet_ready = $BulletReady
onready var bullet_fired = $BulletFired

var slot_empty = true
var slot_loaded = false

func init():
	empty_slot()

func empty_slot():
	slot_empty = true
	bullet_ready.hide()
	bullet_fired.hide()

func load_bullet():
	slot_empty = false
	slot_loaded = true
	bullet_ready.show()
	bullet_fired.hide()

func shoot_bullet():
	slot_loaded = false
	bullet_ready.hide()
	bullet_fired.show()

func is_slot_empty():
	return slot_empty

func does_slot_have_empty_shell():
	return !slot_empty and !slot_loaded

func can_shoot():
	return !slot_empty and slot_loaded

func get_state_num():
	if is_slot_empty():
		return 0
	elif can_shoot():
		return 1
	return 2

func set_state_from_num(state_num: int):
	empty_slot()
	if state_num == 1:
		load_bullet()
	elif state_num == 2:
		load_bullet()
		shoot_bullet()
