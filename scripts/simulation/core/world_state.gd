class_name WorldState
extends RefCounted

const TerrainStateScript := preload("res://scripts/simulation/terrain_state.gd")
const GridOccupancyScript := preload("res://scripts/simulation/grid_occupancy.gd")

var next_entity_id := 1
var next_item_id := 1
var simulation_tick := 0
var entities: Dictionary[int, RefCounted] = {}
var terrain := TerrainStateScript.new()
var occupancy := GridOccupancyScript.new()


func initialize_terrain(
		grid_size: Vector2i,
		seed_value: int,
		field_count: int,
		minimum_radius: int,
		maximum_radius: int
) -> void:
	terrain.generate_iron_fields(grid_size, seed_value, field_count, minimum_radius, maximum_radius)


func allocate_entity_id() -> int:
	var result := next_entity_id
	next_entity_id += 1
	return result


func allocate_item_id() -> int:
	var result := next_item_id
	next_item_id += 1
	return result


func try_add_entity(entity: RefCounted, occupied_cells: Array[Vector2i]) -> bool:
	# 实体和占用在同一个权威对象中提交；占用失败时不会产生半个实体。
	if entity == null or entity.id <= 0 or entities.has(entity.id):
		return false
	if not occupancy.occupy(entity.id, occupied_cells):
		return false
	entities[entity.id] = entity
	return true


func remove_entity(entity_id: int) -> bool:
	if not entities.has(entity_id):
		return false
	if not occupancy.release(entity_id):
		return false
	entities.erase(entity_id)
	return true


func get_entity(entity_id: int) -> RefCounted:
	return entities.get(entity_id)


func get_entity_at(cell: Vector2i) -> RefCounted:
	var entity_id := occupancy.get_entity_at(cell)
	return entities.get(entity_id)


func get_sorted_entity_ids() -> Array[int]:
	var ids: Array[int] = []
	for entity_id in entities:
		ids.append(entity_id)
	ids.sort()
	return ids
