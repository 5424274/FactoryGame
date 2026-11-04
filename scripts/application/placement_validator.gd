class_name PlacementValidator
extends RefCounted

const PlacementResultScript := preload("res://scripts/application/placement_result.gd")
const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")

var _world
var _grid_size: Vector2i


func _init(world, grid_size: Vector2i) -> void:
	_world = world
	_grid_size = grid_size


func validate(
		definition_id: StringName,
		origin: Vector2i,
		rotation_quarters: int
) -> RefCounted:
	if not StructureCatalogScript.is_valid(definition_id):
		return PlacementResultScript.new(false, PlacementResultScript.Failure.UNKNOWN_DEFINITION)

	var footprint_size := StructureCatalogScript.get_rotated_footprint(definition_id, rotation_quarters)
	var cells := get_footprint_cells(origin, footprint_size)
	for cell in cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= _grid_size.x or cell.y >= _grid_size.y:
			return PlacementResultScript.new(false, PlacementResultScript.Failure.OUT_OF_BOUNDS, cells)
	if not _world.occupancy.can_occupy(cells):
		return PlacementResultScript.new(false, PlacementResultScript.Failure.OCCUPIED, cells)
	if definition_id == StructureCatalogScript.MINER_ID and count_iron_cells(cells) == 0:
		return PlacementResultScript.new(false, PlacementResultScript.Failure.MINER_REQUIRES_IRON, cells)
	return PlacementResultScript.new(true, PlacementResultScript.Failure.NONE, cells)


func get_footprint_cells(origin: Vector2i, footprint_size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(footprint_size.y):
		for x in range(footprint_size.x):
			cells.append(origin + Vector2i(x, y))
	return cells


func count_iron_cells(cells: Array[Vector2i]) -> int:
	var count := 0
	for cell in cells:
		if _world.terrain.is_iron(cell):
			count += 1
	return count
