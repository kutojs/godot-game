extends Node2D

export var max_health = 100
var cur_health = 0
var heal_amnt = 50

signal died
signal syringe_used
signal hurt_by_timer

onready var anim_player = $AnimationPlayer

var syringe_obj = preload("res://player/health_ui/Syringe.tscn")
var syringes_held = 0

var dead = false


func _ready():
	init()

var initialized = false
func init():
	if initialized:
		return
	initialized = true
	cur_health = max_health

var ui_visible = false
func show_ui():
	ui_visible = true
	anim_player.play("slide_in", 0.2)

func hide_ui():
	ui_visible = false
	anim_player.play("slide_out", 0.2)

func heal():
	if dead:
		return
	if cur_health >= max_health:
		return
	cur_health += heal_amnt
	if cur_health > max_health:
		cur_health = max_health
	update_health_display()

func hurt(amnt: int, make_sound=true):
	if dead:
		return
	cur_health -= amnt
	if cur_health < 0:
		emit_signal("died")
		dead = true
		$DeathSound.play()
	elif make_sound:
		$HurtSounds.play()
	update_health_display()

func timer_hurt():
	hurt(1, false)
	emit_signal("hurt_by_timer")

func update_health_display():
	var p_bot_pos = $ParasiteStartPos.global_position.y
	var p_top_pos = $ParasiteEndPos.global_position.y
	var t = 1.0 - float(cur_health)/max_health
	$Parasite.global_position.y = lerp(p_bot_pos, p_top_pos, t)

func set_syringes_held(amnt: int):
	syringes_held = amnt
	update_syringe_display()

func update_syringe_display():
	for child in $Syringes.get_children():
		child.queue_free()
	for i in range(syringes_held):
		call_deferred("create_ui_syringe", $Syringes.global_position + Vector2(i*20, 0))

func create_ui_syringe(pos):
	var syringe_inst = syringe_obj.instance()
	$Syringes.add_child(syringe_inst)
	syringe_inst.global_position = pos

var item_grabbed = null
func grab_item(pos: Vector2):
	var ui_items = Utility.get_ui_items_at_point(pos, 8, get_world_2d().get_direct_space_state())
	if ui_items.size() > 0:
		var ui_item = ui_items[0]
		if "Syringe" in ui_item.name:
			ui_item.queue_free()
			item_grabbed = syringe_obj.instance()
			item_grabbed.global_position = pos
			item_grabbed.global_rotation_degrees = 90
			item_grabbed.collision_layer = 0
			call_deferred("add_child", item_grabbed)
			$PickupSyringeSound.play()

func drag_item(pos: Vector2):
	if is_instance_valid(item_grabbed):
		item_grabbed.global_position = pos
	else:
		return
	
	if "Syringe" in item_grabbed.name:
		var ui_items = Utility.get_ui_items_at_point(pos, 8, get_world_2d().get_direct_space_state())
		if ui_items.size() > 0:
			var ui_item = ui_items[0]
			if "Parasite" in ui_item.name:
				item_grabbed.queue_free()
				syringes_held -= 1
				emit_signal("syringe_used")
				$Parasite/Parasite/AnimationPlayer.play("heal")

func release_item(pos: Vector2):
	if !is_instance_valid(item_grabbed):
		return
	
	item_grabbed.queue_free()
	item_grabbed = null
	update_syringe_display()
	$PickupSyringeSound.play()
