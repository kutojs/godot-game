extends KinematicBody2D

enum STATES {NORMAL, INVENTORY, DEAD}
var cur_state = STATES.NORMAL

onready var ui = $Camera2D/UI
onready var gun_ui = $Camera2D/UI/GunUI
onready var health_ui = $Camera2D/UI/HealthUI

onready var gun_on_body = $Graphics/BodyPivot/Gun
onready var physical_hand = $Hand
onready var body = $Graphics/BodyPivot
onready var shoulder = $Graphics/UpperArmPivot
onready var elbow = $Graphics/UpperArmPivot/LowerArmPivot
onready var hand_base = $Graphics/UpperArmPivot/LowerArmPivot/HandBase

onready var muzzle_flash = $Graphics/UpperArmPivot/LowerArmPivot/HandBase/Gun/MuzzleFlash
onready var pickup_area = $Hand/PickupArea
onready var gun_raycast = $Graphics/UpperArmPivot/LowerArmPivot/HandBase/GunRayCast2D
onready var blood_sprayer = $Graphics/BodyPivot/BloodSprayer

var upper_arm_length = 0.0
var lower_arm_length = 0.0
var total_arm_length = 0.0

var min_hand_dist = 30

var has_gun = false
var num_of_ammo_in_pickups = 3
var ammo_held = 0
var max_ammo_can_carry = 12
var health_syringes_held = 0
var max_health_syringes_can_carry = 3

var hit_effect = preload("res://Effects/HitEffect.tscn")

signal start_move
signal picked_up_syringe
signal inventory_opened
signal injected_syringe
signal picked_up_gun
signal bullet_loaded
signal shot_gun

func _ready():
	upper_arm_length = elbow.position.x
	lower_arm_length = hand_base.position.x
	total_arm_length = upper_arm_length + lower_arm_length
	pickup_area.connect("body_entered", self, "handle_pickup")
	gun_ui.connect("bullet_loaded", self, "dec_ammo_held")
	gun_ui.connect("bullet_loaded", self, "emit_loaded_bullet")
	health_ui.connect("syringe_used", self, "dec_syringes_held")
	health_ui.connect("syringe_used", self, "emit_syringe_injected")
	health_ui.connect("hurt_by_timer", self, "cough_blood")
	health_ui.connect("died", self, "set_dead_state")
	gun_on_body.hide()
	$CanvasLayer/RestartPanel/Button.connect("button_up", self, "restart")

func cough_blood():
	if cur_state != STATES.DEAD and randi()%3==0:
		blood_sprayer.spawn_blood_decal(blood_sprayer.global_position)
		$Camera2D/UI/HealthUI/CoughSounds.play()

func _input(event):
	if cur_state == STATES.DEAD:
		return
	if event is InputEventMouseButton and event.is_pressed():
		if cur_state == STATES.NORMAL and (event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN):
			set_inventory_state()
		else:
			if event.button_index == BUTTON_WHEEL_DOWN:
				ui.spin_chamber(true)
			if event.button_index == BUTTON_WHEEL_UP:
				ui.spin_chamber(false)

func _process(delta):
	update_arm_graphics()
	if cur_state == STATES.INVENTORY:
		process_inventory_state(delta)

var last_m_pos = Vector2.ZERO
var last_hand_pos = Vector2.ZERO
func _physics_process(delta):
	if cur_state == STATES.NORMAL:
		process_normal_state(delta)

func exit_states():
	ui.hide_ui()
	
func set_normal_state():
	exit_states()
	cur_state = STATES.NORMAL
	
func set_inventory_state():
	exit_states()
	cur_state = STATES.INVENTORY
	ui.show_ui()
	emit_signal("inventory_opened")

func set_dead_state():
	exit_states()
	cur_state = STATES.DEAD
	$CanvasLayer/RestartPanel/AnimationPlayer.play("fade_in")

func process_normal_state(delta):
	var m_pos = get_global_mouse_position()
	hide_gun()
	if Input.is_action_pressed("side_action") and has_gun:
		show_gun()
		set_hand_closed()
		move_hand_to_pos(m_pos, delta)
		last_hand_pos = physical_hand.global_position
		if Input.is_action_just_pressed("main_action"):
			shoot()
	elif Input.is_action_pressed("main_action"):
		if Input.is_action_just_pressed("main_action"):
			$GrabGround.play()
		set_hand_closed()
		emit_signal("start_move")
		var move_vec = m_pos - last_m_pos
		var shoulder_pos = shoulder.global_position
		var hand_pos = physical_hand.global_position
		var new_s_pos = shoulder_pos - move_vec
		if new_s_pos.distance_to(hand_pos) > total_arm_length:
			#var adjusted_pos = hand_pos.direction_to(new_s_pos) * total_arm_length
			#move_vec = shoulder_pos - adjusted_pos
			move_vec = Vector2.ZERO
		
		rotate_body_to_dir(-move_vec)
		move_and_slide(-move_vec / delta, Vector2.ZERO)
		move_hand_to_pos(last_hand_pos, delta)
		if move_vec.length_squared() > 5:
			if !$SlideSounds.is_playing():
				$SlideSounds.play()
		#else:
			#$SlideSounds.stop()
		
	else:
		set_hand_open()
		move_hand_to_pos(m_pos, delta)
		last_hand_pos = physical_hand.global_position
	last_m_pos = m_pos

func process_inventory_state(_delta):
	if Input.is_action_just_pressed("side_action"):
		set_normal_state()
		return
	var m_pos = get_global_mouse_position()
	if Input.is_action_just_pressed("main_action"):
		ui.grab_item(m_pos)
	if Input.is_action_pressed("main_action"):
		ui.drag_item(m_pos)
	if Input.is_action_just_released("main_action"):
		ui.release_item(m_pos)

func rotate_body_to_dir(rotate_vec: Vector2):
	var right = body.to_global(Vector2.RIGHT) - body.global_position 
	var s = 1
	if right.dot(rotate_vec) < 0:
		s = -1
	body.global_rotation_degrees += s * rotate_vec.length()  / 2

func move_hand_to_pos(goal_pos, delta):
	var hand_pos = physical_hand.global_position
	var shoulder_pos = shoulder.global_position
	
	var hand_move_vec = goal_pos - shoulder_pos
	if hand_move_vec.length() > total_arm_length:
		hand_move_vec = hand_move_vec.normalized() * total_arm_length
	physical_hand.global_position = shoulder_pos
	physical_hand.move_and_slide(hand_move_vec/delta, Vector2.ZERO)

func update_arm_graphics():
	var shoulder_pos = shoulder.global_position
	var hand_pos = physical_hand.global_position
	var shoulder_to_hand = hand_pos - shoulder_pos
	var shoulder_to_hand_dist = shoulder_to_hand.length()
	shoulder_to_hand_dist = clamp(shoulder_to_hand_dist, min_hand_dist, total_arm_length)
	shoulder.global_rotation = atan2(shoulder_to_hand.y, shoulder_to_hand.x)
	var angles = SSS_calc(upper_arm_length, lower_arm_length, shoulder_to_hand_dist)
	shoulder.global_rotation += angles.B
	elbow.rotation = angles.C


func SSS_calc(side_a, side_b, side_c):
	if side_c >= side_a + side_b:
		return {"A": 0, "B": 0, "C": 0}
	var angle_a = law_of_cos(side_b, side_c, side_a)
	var angle_b = law_of_cos(side_c, side_a, side_b) + PI
	var angle_c = PI - angle_a - angle_b
	
	return {"A": angle_a, "B": angle_b-PI, "C": angle_c}

func law_of_cos(a, b, c):
	if 2 * a * b == 0:
		return 0
	return acos( (a * a + b * b - c * c) / ( 2 * a * b) )

func set_hand_open():
	hand_base.get_node("HandClosed").hide()
	hand_base.get_node("HandOpen").show()
	
func set_hand_closed():
	hand_base.get_node("HandClosed").show()
	hand_base.get_node("HandOpen").hide()

func show_gun():
	hand_base.get_node("Gun").show()
	gun_on_body.hide()

func hide_gun():
	hand_base.get_node("Gun").hide()
	if has_gun:
		gun_on_body.show()
	
func handle_pickup(body : PhysicsBody2D):
	if body is Pickup:
		if "Bullets" in body.name and ammo_held < max_ammo_can_carry:
			$PickupBulletSound.play()
			ammo_held += num_of_ammo_in_pickups
			ammo_held = clamp(ammo_held, 0, max_ammo_can_carry)
			body.queue_free()
			gun_ui.set_ammo_held(ammo_held)
		if "Health" in body.name and health_syringes_held < max_health_syringes_can_carry:
			$PickupSyringeSound.play()
			health_syringes_held += 1
			health_ui.set_syringes_held(health_syringes_held)
			body.queue_free()
			emit_signal("picked_up_syringe")
		if "Gun" in body.name and !has_gun:
			$PickupGunSound.play()
			hide_gun()
			has_gun = true
			ui.has_gun = true
			body.queue_free()
			emit_signal("picked_up_gun")

func shoot():
	if gun_ui.shoot():
		emit_signal("shot_gun")
		muzzle_flash.flash()
		var bodies = $Hand/HitArea.get_overlapping_bodies()
		var shot_something = false
		for b in bodies:
			if b.is_in_group("enemies"):
				b.hurt()
				shot_something = true
		
		if bodies.size() == 0 and gun_raycast.is_colliding():
			shot_something = true
			if gun_raycast.get_collider().has_method("hurt"):
				gun_raycast.get_collider().hurt()
			else:
				var hit_pos = gun_raycast.get_collision_point()
				var he = hit_effect.instance()
				get_tree().get_root().add_child(he)
				he.global_position = hit_pos
		if shot_something:
			$Gunshot.play()
	$GunHammerClick.play()

func hurt(amnt: int):
	health_ui.hurt(amnt)
	blood_sprayer.spray_blood()

func dec_ammo_held():
	ammo_held -= 1
func dec_syringes_held():
	health_syringes_held -= 1

func emit_syringe_injected():
	emit_signal("injected_syringe")
func emit_loaded_bullet():
	emit_signal("bullet_loaded")

func _save():
	return {
		"has_gun": has_gun,
		"ammo_held": ammo_held,
		"syringes_held": health_syringes_held,
		"health": health_ui.cur_health,
		"gun_data": gun_ui._save()
	}

func _load(save_data: Dictionary):
	health_ui.init()
	gun_ui.init()
	if "has_gun" in save_data:
		has_gun = save_data.has_gun
		ui.has_gun = has_gun
	if "ammo_held" in save_data:
		ammo_held = save_data.ammo_held
		gun_ui.set_ammo_held(ammo_held)
	if "syringes_held" in save_data:
		health_syringes_held = save_data.syringes_held
		health_ui.set_syringes_held(health_syringes_held)
	if "syringes_held" in save_data: 
		health_ui.cur_health = save_data.health
		health_ui.update_health_display()
	if "gun_data" in save_data: 
		gun_ui._load(save_data.gun_data)

func restart():
	LevelManager.restart_level()
