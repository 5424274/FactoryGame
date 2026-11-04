class_name BeltState
extends RefCounted

var direction: Vector2i
var items: Array[RefCounted] = []


func _init(p_direction: Vector2i) -> void:
	direction = p_direction
