extends Node2D

var blood_obj = preload("res://Effects/BloodSprite.tscn")
var min_blood_decals = 5
var max_blood_decals = 8
var spray_dist = 200

func spray_blood():
	var num_of_decals = min_blood_decals+(randi()%(max_blood_decals-min_blood_decals))
	$Particles2D.restart()
	$SpraySound.play()
	for _i in range(num_of_decals):
		spray_one_blood()

func spray_one_blood():
	var spray_dir = Vector2.RIGHT.rotated(rand_range(0.0,2*PI))
	var spray_vec = spray_dir * rand_range(0.0, spray_dist)
	var space_state = get_world_2d().direct_space_state
	var spawn_pos = Vector2()
	var result = space_state.intersect_ray(global_position, global_position+spray_vec, [], 1)
	if result:
		spawn_pos = result.position - spray_dir * 40 #avoid clipping into wall
	else:
		spawn_pos = global_position+spray_vec
	spawn_blood_decal(spawn_pos)

func spawn_blood_decal(pos):
	var blood_inst = blood_obj.instance()
	get_tree().get_root().add_child(blood_inst)
	blood_inst.global_position = pos
	blood_inst.add_to_group("instanced")
