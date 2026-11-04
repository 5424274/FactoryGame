class_name TerrainState
extends RefCounted

# 地表状态只保存会影响游戏规则的格子数据，不依赖纹理或绘制节点。
const GROUND_ID := &"base:ground"
const IRON_ID := &"base:iron_ore"

var _terrain_by_cell: Dictionary[Vector2i, StringName] = {}


func generate_iron_fields(
		grid_size: Vector2i,
		seed_value: int,
		field_count: int,
		minimum_radius: int,
		maximum_radius: int
) -> void:
	_terrain_by_cell.clear()
	if grid_size.x <= 0 or grid_size.y <= 0 or field_count <= 0:
		return

	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for _field_index in range(field_count):
		var center := Vector2i(
			random.randi_range(0, grid_size.x - 1),
			random.randi_range(0, grid_size.y - 1)
		)
		var radius := random.randi_range(minimum_radius, maximum_radius)
		_paint_iron_field(center, radius, grid_size, random)


func get_terrain(cell: Vector2i) -> StringName:
	return _terrain_by_cell.get(cell, GROUND_ID)


func is_iron(cell: Vector2i) -> bool:
	return get_terrain(cell) == IRON_ID


func get_iron_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _terrain_by_cell:
		if _terrain_by_cell[cell] == IRON_ID:
			cells.append(cell)
	return cells


func get_iron_cell_count() -> int:
	return get_iron_cells().size()


func _paint_iron_field(
		center: Vector2i,
		radius: int,
		grid_size: Vector2i,
		random: RandomNumberGenerator
) -> void:
	# 距矿区中心越近，成为铁矿格的概率越高，边缘因此自然且不规则。
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
				continue
			var distance_ratio := Vector2(cell - center).length() / float(radius)
			if distance_ratio > 1.0:
				continue
			var iron_chance := lerpf(0.88, 0.28, distance_ratio)
			if random.randf() <= iron_chance:
				_terrain_by_cell[cell] = IRON_ID
