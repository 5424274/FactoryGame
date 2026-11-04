class_name PlacementService
extends RefCounted

signal entity_placed(entity: RefCounted)

const PlacementValidatorScript := preload("res://scripts/application/placement_validator.gd")
const PlacementResultScript := preload("res://scripts/application/placement_result.gd")
const EntityStateScript := preload("res://scripts/simulation/core/entity_state.gd")
const MinerStateScript := preload("res://scripts/simulation/core/miner_state.gd")
const BeltStateScript := preload("res://scripts/simulation/core/belt_state.gd")
const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")

const DEFAULT_DIRECTION := Vector2i.DOWN

var _world
var _validator


func _init(world, grid_size: Vector2i) -> void:
	_world = world
	_validator = PlacementValidatorScript.new(world, grid_size)


func validate(
		definition_id: StringName,
		origin: Vector2i,
		rotation_quarters: int
) -> RefCounted:
	return _validator.validate(definition_id, origin, rotation_quarters)


func place(
		definition_id: StringName,
		origin: Vector2i,
		rotation_quarters: int
) -> RefCounted:
	var result: RefCounted = validate(definition_id, origin, rotation_quarters)
	if not result.allowed:
		return result

	var entity_id: int = _world.allocate_entity_id()
	var footprint_size := StructureCatalogScript.get_rotated_footprint(definition_id, rotation_quarters)
	var entity: RefCounted = EntityStateScript.new(
		entity_id,
		definition_id,
		origin,
		footprint_size,
		rotation_quarters
	)
	_attach_capability_state(entity, result.occupied_cells)
	if not _world.try_add_entity(entity, result.occupied_cells):
		return PlacementResultScript.new(false, PlacementResultScript.Failure.COMMIT_FAILED, result.occupied_cells)

	result.entity = entity
	# 事件发生在权威状态提交后；View 失败不影响实体与占用。
	entity_placed.emit(entity)
	return result


func get_footprint_cells(origin: Vector2i, footprint_size: Vector2i) -> Array[Vector2i]:
	return _validator.get_footprint_cells(origin, footprint_size)


func count_iron_cells(cells: Array[Vector2i]) -> int:
	return _validator.count_iron_cells(cells)


func _attach_capability_state(entity: RefCounted, occupied_cells: Array[Vector2i]) -> void:
	if entity.definition_id == StructureCatalogScript.MINER_ID:
		var iron_count: int = count_iron_cells(occupied_cells)
		entity.miner = MinerStateScript.new(get_miner_efficiency_percent(iron_count))
	elif entity.definition_id == StructureCatalogScript.CONVEYOR_ID:
		var direction := StructureCatalogScript.rotate_direction(DEFAULT_DIRECTION, entity.rotation_quarters)
		entity.belt = BeltStateScript.new(direction)


func get_miner_efficiency_percent(iron_cell_count: int) -> int:
	match clampi(iron_cell_count, 0, 4):
		4:
			return 100
		3:
			return 75
		2:
			return 40
		1:
			return 15
	return 0
