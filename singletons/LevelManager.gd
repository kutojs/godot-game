extends Node

var level_list = [
	"res://levels/Intro.tscn",
	"res://levels/Tutorial1.tscn",
	"res://levels/FirstMonster.tscn",
	"res://levels/MonsterCorridor.tscn",
	"res://levels/Tutorial2.tscn",
	"res://levels/NotEnoughBullets.tscn",
	"res://levels/ServerRoom.tscn",
	"res://levels/Horde.tscn",
	"res://levels/Outro.tscn"
]
var level_ind = 0
var save_data = {}

func load_next_level():
	level_ind += 1
	level_ind %= level_list.size()
	
	if get_player():
		save_data = get_player()._save()
	get_tree().call_group("instanced", "queue_free")
	get_tree().change_scene(level_list[level_ind])
	yield(get_tree(), "idle_frame")
	if get_player():
		get_player()._load(save_data)
	$NextLevelSound.play()

func restart_level():
	get_tree().call_group("instanced", "queue_free")
	get_tree().reload_current_scene()
	yield(get_tree(), "idle_frame")
	if get_player():
		get_player()._load(save_data)

func get_player():
	var p = get_tree().get_nodes_in_group("player")
	if p.size() > 0:
		return p[0]
	return null

func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
