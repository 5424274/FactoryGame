class_name EntityState
extends RefCounted

var id: int
var definition_id: StringName
var origin: Vector2i
var footprint_size: Vector2i
var rotation_quarters: int
var miner: RefCounted
var belt: RefCounted


func _init(
		p_id: int,
		p_definition_id: StringName,
		p_origin: Vector2i,
		p_footprint_size: Vector2i,
		p_rotation_quarters: int
) -> void:
	id = p_id
	definition_id = p_definition_id
	origin = p_origin
	footprint_size = p_footprint_size
	rotation_quarters = posmod(p_rotation_quarters, 4)
