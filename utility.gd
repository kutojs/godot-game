extends Node2D

class_name Utility

const grab_radius = 10
static func get_ui_items_at_point(point: Vector2, layer_mask, world):
	var query = Physics2DShapeQueryParameters.new()
	var select_transform = Transform2D()
	select_transform.origin = point
	query.set_transform(select_transform)
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = grab_radius
	query.set_shape(circle_shape)
	query.collision_layer = layer_mask
	var space_state = world#get_world_2d().get_direct_space_state()
	var result = space_state.intersect_shape(query)
	var objects = []
	for item_data in result:
		objects.append(item_data.collider)
	return objects
