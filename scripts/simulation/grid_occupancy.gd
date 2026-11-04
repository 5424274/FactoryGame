class_name GridOccupancy
extends RefCounted

# 单元格到实体 ID 的正向索引，是判断放置冲突的权威来源。
var _cell_to_entity: Dictionary[Vector2i, int] = {}
# 实体到占用单元格的反向索引，保证以后拆除机械时可以完整释放占地。
var _entity_to_cells: Dictionary[int, Array] = {}


func can_occupy(cells: Array[Vector2i]) -> bool:
	# 同一批格子不允许重复；否则登记数量和机械真实占地会不一致。
	var unique_cells: Dictionary[Vector2i, bool] = {}
	for cell in cells:
		if unique_cells.has(cell) or _cell_to_entity.has(cell):
			return false
		unique_cells[cell] = true
	return not cells.is_empty()


func occupy(entity_id: int, cells: Array[Vector2i]) -> bool:
	# 一次性验证后再登记，避免多格机械只占用一部分格子的半完成状态。
	if entity_id <= 0 or _entity_to_cells.has(entity_id) or not can_occupy(cells):
		return false

	var stored_cells: Array[Vector2i] = []
	stored_cells.assign(cells)
	for cell in stored_cells:
		_cell_to_entity[cell] = entity_id
	_entity_to_cells[entity_id] = stored_cells
	return true


func release(entity_id: int) -> bool:
	if not _entity_to_cells.has(entity_id):
		return false

	var stored_cells: Array = _entity_to_cells[entity_id]
	for cell_value in stored_cells:
		var cell: Vector2i = cell_value
		_cell_to_entity.erase(cell)
	_entity_to_cells.erase(entity_id)
	return true


func is_occupied(cell: Vector2i) -> bool:
	return _cell_to_entity.has(cell)


func get_entity_at(cell: Vector2i) -> int:
	return _cell_to_entity.get(cell, 0)


func get_cells_for_entity(entity_id: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not _entity_to_cells.has(entity_id):
		return result

	for cell_value in _entity_to_cells[entity_id]:
		var cell: Vector2i = cell_value
		result.append(cell)
	return result


func get_occupied_cell_count() -> int:
	return _cell_to_entity.size()


func get_entity_count() -> int:
	return _entity_to_cells.size()
