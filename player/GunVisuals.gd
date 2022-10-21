extends Node2D

var ammo_held = 0

onready var bullet_slots = $ChamberPivot/GunChamber.get_children()
onready var anim_player = $AnimationPlayer
onready var chamber = $ChamberPivot

onready var idle_bullets_display = $Bullets
var bullet_idle_obj = preload("res://player/gun_ui/BulletIdle.tscn")
var idle_bullets_dist = 60

var bullet_held_obj = preload("res://player/gun_ui/BulletHeld.tscn")
var bullet_shell_held_obj = preload("res://player/gun_ui/BulletShellHeld.tscn")
var bullet_shell_obj = preload("res://player/gun_ui/BulletShell.tscn")

signal bullet_loaded

func _ready():
	init()

var initialized = false
func init():
	if initialized:
		return
	initialized = true
	for slot in bullet_slots:
		slot.init()

func set_ammo_held(_ammo_held: int):
	ammo_held = _ammo_held
	update_bullet_display()

func update_bullet_display():
	if !ui_visible:
		return
	for c in idle_bullets_display.get_children():
		c.queue_free()
	for i in range(ammo_held):
		call_deferred("instance_idle_bullet", Vector2((i/6)* 15 + (i%6) * idle_bullets_dist, 80 * (i/6)))

func instance_idle_bullet(pos: Vector2):
	var bullet_idle_inst = bullet_idle_obj.instance()
	idle_bullets_display.add_child(bullet_idle_inst)
	bullet_idle_inst.position = pos
	bullet_idle_inst.connect("mouse_entered", self, "bullet_moused_over")

var ui_visible = false
func show_ui():
	ui_visible = true
	anim_player.play("slide_in", 0.2)
	update_bullet_display()

func hide_ui():
	ui_visible = false
	anim_player.play("slide_out", 0.2)
	update_ready_slot()

var spin_amnt = 10.0
func spin_chamber(up: bool):
	var s = 1
	if up:
		s = -1
	chamber.rotate(deg2rad(spin_amnt * s))
	if ui_visible:
		$RotateChamberSound.play()

var item_grabbed = null
func grab_item(pos: Vector2):
	var ui_items = Utility.get_ui_items_at_point(pos, 8, get_world_2d().get_direct_space_state())
	if ui_items.size() > 0:
		var ui_item = ui_items[0]
		if "BulletIdle" in ui_item.name:
			ui_item.queue_free()
			item_grabbed = bullet_held_obj.instance()
			item_grabbed.global_position = pos
			call_deferred("add_child", item_grabbed)
			$GrabBulletSound.play()
		if "BulletSlot" in ui_item.name and ui_item.does_slot_have_empty_shell():
			item_grabbed = bullet_shell_held_obj.instance()
			item_grabbed.global_position = pos
			call_deferred("add_child", item_grabbed)
			ui_item.empty_slot()
			$GrabBulletSound.play()

func drag_item(pos: Vector2):
	if is_instance_valid(item_grabbed):
		item_grabbed.global_position = pos
	else:
		return

func release_item(pos: Vector2):
	if !is_instance_valid(item_grabbed):
		return
	if "BulletShell" in item_grabbed.name:
		call_deferred("spawn_bullet_shell", pos)
		return
	var ui_items = Utility.get_ui_items_at_point(pos, 8, get_world_2d().get_direct_space_state())
	if ui_items.size() > 0 and "BulletSlot" in ui_items[0].name and ui_items[0].is_slot_empty():
		ammo_held -= 1
		ui_items[0].load_bullet()
		emit_signal("bullet_loaded")
		$InsertBulletSound.play()
	else:
		$ReturnBulletSound.play()
	
	item_grabbed.queue_free()
	item_grabbed = null
	update_bullet_display()
	

func spawn_bullet_shell(pos):
	var bs = bullet_shell_obj.instance()
	add_child(bs)
	bs.global_position = pos
	item_grabbed.queue_free()
	item_grabbed = null
	bs.connect("tree_exited", $DropBulletSounds, "play")

var bullet_slot_ready = 0
func shoot() -> bool: # returns if shot was successful
	var next_slot : BulletSlot = bullet_slots[bullet_slot_ready]
	bullet_slot_ready += 1
	bullet_slot_ready %= bullet_slots.size()
	#chamber.rotate(2*PI / bullet_slots.size())
	update_chamber_rotation()
	
	if !next_slot.can_shoot():
		return false
	next_slot.shoot_bullet()
	return true

func update_ready_slot():
	var dist = -1
	var closest_ind = 0
	var ind = 0
	var next_round_pos = $NextRoundPos.global_position
	for slot in bullet_slots:
		var n_dist = slot.global_position.distance_squared_to(next_round_pos)
		if dist < 0 or dist > n_dist:
			bullet_slot_ready = ind
			dist = n_dist
		ind += 1
	update_chamber_rotation()

func update_chamber_rotation():
	chamber.global_rotation = bullet_slot_ready * 2*PI / bullet_slots.size()

func _save():
	var clip_data = []
	for slot in bullet_slots:
		clip_data.append(slot.get_state_num())
	return {
		"chamber_rotation": chamber.global_rotation,
		"clip_data": clip_data
	}

func _load(data: Dictionary):
	if "chamber_rotation" in data:
		chamber.global_rotation = data.chamber_rotation
	if "clip_data" in data:
		for i in range(bullet_slots.size()):
			bullet_slots[i].set_state_from_num(data.clip_data[i])
