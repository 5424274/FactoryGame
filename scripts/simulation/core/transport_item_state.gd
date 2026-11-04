class_name TransportItemState
extends RefCounted

var id: int
var definition_id: StringName


func _init(p_id: int, p_definition_id: StringName) -> void:
	id = p_id
	definition_id = p_definition_id
