class_name FactorySimulation
extends RefCounted

const TransportItemStateScript := preload("res://scripts/simulation/core/transport_item_state.gd")
const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")

const IRON_ITEM_ID := &"base:iron_ore"
const CONVEYOR_CAPACITY := 2
const MINING_WORK_PER_ITEM := 300
const DEFAULT_DIRECTION := Vector2i.DOWN

class TransferPlan:
	extends RefCounted
	var source_entity_id: int
	var target_entity_id: int

	func _init(p_source_entity_id: int, p_target_entity_id: int) -> void:
		source_entity_id = p_source_entity_id
		target_entity_id = p_target_entity_id


var _world
var _belt_entity_by_cell: Dictionary[Vector2i, int] = {}


func _init(world) -> void:
	_world = world
	rebuild_indexes()


func rebuild_indexes() -> void:
	_belt_entity_by_cell.clear()
	for entity_id in _world.get_sorted_entity_ids():
		var entity: RefCounted = _world.get_entity(entity_id)
		if entity != null and entity.belt != null:
			_belt_entity_by_cell[entity.origin] = entity.id


func on_entity_placed(entity: RefCounted) -> void:
	if entity != null and entity.belt != null:
		_belt_entity_by_cell[entity.origin] = entity.id


func advance_tick() -> void:
	_world.simulation_tick += 1
	_move_belt_items()
	_run_miners()


func can_belt_accept_from(belt_cell: Vector2i, source_cell: Vector2i) -> bool:
	var belt: RefCounted = get_belt_at(belt_cell)
	if belt == null:
		return false
	if source_cell == belt_cell + belt.direction:
		return false
	if absi(source_cell.x - belt_cell.x) + absi(source_cell.y - belt_cell.y) != 1:
		return false
	return belt.items.size() < CONVEYOR_CAPACITY


func try_insert_item(belt_cell: Vector2i, source_cell: Vector2i, item_id: StringName) -> bool:
	if not can_belt_accept_from(belt_cell, source_cell):
		return false
	var belt: RefCounted = get_belt_at(belt_cell)
	belt.items.append(TransportItemStateScript.new(_world.allocate_item_id(), item_id))
	return true


func get_belt_at(cell: Vector2i) -> RefCounted:
	var entity_id: int = _belt_entity_by_cell.get(cell, 0)
	var entity: RefCounted = _world.get_entity(entity_id)
	return entity.belt if entity != null else null


func get_belt_item_count(cell: Vector2i) -> int:
	var belt: RefCounted = get_belt_at(cell)
	return belt.items.size() if belt != null else 0


func get_belt_items(cell: Vector2i) -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	var belt: RefCounted = get_belt_at(cell)
	if belt != null:
		result.assign(belt.items)
	return result


func get_belt_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _belt_entity_by_cell:
		cells.append(cell)
	cells.sort_custom(_cell_less)
	return cells


func get_belt_direction(cell: Vector2i) -> Vector2i:
	var belt: RefCounted = get_belt_at(cell)
	return belt.direction if belt != null else Vector2i.ZERO


func _move_belt_items() -> void:
	var plans: Array[TransferPlan] = []
	var reserved_inputs: Dictionary[int, int] = {}
	# 实体 ID 是显式、稳定的仲裁顺序，与 Dictionary 插入顺序无关。
	for source_entity_id in _world.get_sorted_entity_ids():
		var source: RefCounted = _world.get_entity(source_entity_id)
		if source == null or source.belt == null or source.belt.items.is_empty():
			continue
		var target_cell: Vector2i = source.origin + source.belt.direction
		var target_id: int = _belt_entity_by_cell.get(target_cell, 0)
		var target: RefCounted = _world.get_entity(target_id)
		if target == null or target.belt == null:
			continue
		if not can_belt_accept_from(target_cell, source.origin):
			continue
		var reserved_count: int = reserved_inputs.get(target.id, 0)
		if target.belt.items.size() + reserved_count >= CONVEYOR_CAPACITY:
			continue
		reserved_inputs[target.id] = reserved_count + 1
		plans.append(TransferPlan.new(source.id, target.id))

	for plan in plans:
		var source: RefCounted = _world.get_entity(plan.source_entity_id)
		var target: RefCounted = _world.get_entity(plan.target_entity_id)
		var item: RefCounted = source.belt.items.pop_front()
		target.belt.items.append(item)


func _run_miners() -> void:
	for entity_id in _world.get_sorted_entity_ids():
		var entity: RefCounted = _world.get_entity(entity_id)
		if entity == null or entity.miner == null:
			continue
		entity.miner.progress_work += entity.miner.efficiency_percent
		if entity.miner.progress_work < MINING_WORK_PER_ITEM:
			continue
		var output_port: Vector2i = entity.origin + StructureCatalogScript.rotate_local_cell(
			Vector2i(1, 1), Vector2i(2, 2), entity.rotation_quarters
		)
		var output_direction: Vector2i = StructureCatalogScript.rotate_direction(DEFAULT_DIRECTION, entity.rotation_quarters)
		var target_belt: Vector2i = output_port + output_direction
		if try_insert_item(target_belt, output_port, IRON_ITEM_ID):
			entity.miner.progress_work -= MINING_WORK_PER_ITEM
		else:
			entity.miner.progress_work = MINING_WORK_PER_ITEM


func _cell_less(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
