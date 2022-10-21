extends KinematicBody2D

enum STATES {IDLE, PATROL, ATTACK, DEAD}
var cur_state = STATES.IDLE

var patrol_points = []

var player : KinematicBody2D
var nav : Navigation2D

export var move_speed = 80
export var health = 4
export var damage = 30
export var attack_range = 100
export var sight_range = 300
export var max_stun_time = 0.1
onready var anim_player = $Graphics/AnimationPlayer

func _ready():
	nav = get_parent()
	player = get_tree().get_nodes_in_group("player")[0]
	if has_node("PatrolPoints"):
		for c in get_node("PatrolPoints").get_children():
			patrol_points.append(c.global_position)
		cur_state = STATES.PATROL

func _physics_process(delta):
	if cur_state == STATES.IDLE:
		process_idle_state(delta)
	elif cur_state == STATES.PATROL:
		process_patrol_state(delta)
	elif cur_state == STATES.ATTACK:
		process_attack_state(delta)

func exit_state():
	pass

func set_idle_state():
	exit_state()
	cur_state = STATES.IDLE
	anim_player.play("idle")

func set_patrol_state():
	exit_state()
	cur_state = STATES.PATROL

func set_attack_state():
	exit_state()
	cur_state = STATES.ATTACK
	$AlertSound.play()

func set_dead_state():
	exit_state()
	cur_state = STATES.DEAD
	$CollisionShape2D.disabled = true
	anim_player.play("death")
	z_index = 4
	$IdleSound.stop()
	$DeathSound.play()

func process_idle_state(delta):
	if can_see_player():
		set_attack_state()

enum PATROL_SUB_STATES {PAUSE, MOVE}
var cur_p_sub_state = PATROL_SUB_STATES.PAUSE
var pause_time = 2.0
var cur_pause_time = 0.0
var patrol_point_ind = 0
func process_patrol_state(delta):
	if can_see_player():
		set_attack_state()
	if cur_p_sub_state == PATROL_SUB_STATES.PAUSE:
		anim_player.play("idle")
		cur_pause_time += delta
		if cur_pause_time > pause_time:
			cur_p_sub_state = PATROL_SUB_STATES.MOVE
			cur_pause_time = 0.0
	elif cur_p_sub_state == PATROL_SUB_STATES.MOVE:
		anim_player.play("walk")
		var next_patrol_point = patrol_points[patrol_point_ind]
		var move_dir = global_position.direction_to(next_patrol_point)
		move_and_slide(move_dir*move_speed, Vector2.ZERO)
		face_dir(move_dir, delta)
		if global_position.distance_squared_to(next_patrol_point)< 20 * 20:
			patrol_point_ind += 1
			patrol_point_ind %= patrol_points.size()
			cur_p_sub_state = PATROL_SUB_STATES.PAUSE

var attacking = false
var cur_stun_time = 0.0
func process_attack_state(delta):
	if cur_stun_time > 0.0:
		cur_stun_time -= delta
		anim_player.play("idle")
		return
	var dist_to_player = global_position.distance_to(player.global_position)
	if attacking:
		pass
	elif dist_to_player < attack_range and can_see_player():
		anim_player.play("attack")
		attacking = true
	else:
		anim_player.play("walk")
		var path = nav.get_simple_path(global_position, player.global_position)
		if path.size() > 1:
			var move_dir = global_position.direction_to(path[1])
			move_and_slide(move_dir*move_speed, Vector2.ZERO)
			face_dir(move_dir, delta)

func deal_damage_attack():
	if player in $AttackArea.get_overlapping_bodies():
		player.hurt(damage)

func finish_attack():
	attacking = false

export var turn_speed = 140
func face_dir(dir: Vector2, delta):
	var r = Vector2.DOWN.rotated(global_rotation)
	var s = 1
	var turn_r = r.dot(dir) < 0
	if turn_r:
		s = -1
	var offset = turn_speed*delta
	var goal_angle = rad2deg(atan2(dir.y, dir.x))
	if abs(angle_difference(global_rotation_degrees, goal_angle)) < offset:
		global_rotation_degrees = goal_angle
	else:
		global_rotation_degrees += turn_speed*delta*s

func hurt():
	if cur_state == STATES.DEAD:
		return
	if cur_state != STATES.ATTACK:
		set_attack_state()
	health -= 1
	cur_stun_time = max_stun_time
	attacking = false
	$BloodSprayer.spray_blood()
	if health <= 0:
		set_dead_state()
	else:
		$HurtSounds.play()

func angle_difference(from, to):
	return fposmod(to - from + 180,  180 * 2) - 180

func can_see_player():
	if global_position.distance_squared_to(player.global_position) > sight_range*sight_range:
		return false
	var dir_to_player = global_position.direction_to(player.global_position)
	var in_sight_arc = dir_to_player.dot(Vector2.RIGHT.rotated(global_rotation)) > 0.8
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, player.global_position, [self], 1)
	if result:
		pass
	else:
		return in_sight_arc
	return false
