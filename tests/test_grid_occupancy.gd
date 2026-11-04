extends SceneTree

const GridOccupancyScript := preload("res://scripts/simulation/grid_occupancy.gd")


func _init() -> void:
	var occupancy := GridOccupancyScript.new()
	var first_cells: Array[Vector2i] = [
		Vector2i(2, 3), Vector2i(3, 3),
		Vector2i(2, 4), Vector2i(3, 4),
	]

	_assert_true(occupancy.can_occupy(first_cells), "empty cells can be occupied")
	_assert_true(occupancy.occupy(1, first_cells), "multi-cell entity occupies atomically")
	_assert_equal(occupancy.get_occupied_cell_count(), 4, "four cells registered")
	_assert_equal(occupancy.get_entity_count(), 1, "one entity registered")
	_assert_equal(occupancy.get_entity_at(Vector2i(3, 4)), 1, "cell resolves entity")
	_assert_false(occupancy.can_occupy([Vector2i(3, 4), Vector2i(4, 4)]), "partial overlap rejected")
	_assert_false(occupancy.occupy(2, [Vector2i(3, 4), Vector2i(4, 4)]), "failed batch changes nothing")
	_assert_equal(occupancy.get_occupied_cell_count(), 4, "failed batch leaves occupancy unchanged")
	_assert_false(occupancy.can_occupy([Vector2i(8, 8), Vector2i(8, 8)]), "duplicate input cells rejected")
	_assert_true(occupancy.release(1), "entity release succeeds")
	_assert_equal(occupancy.get_occupied_cell_count(), 0, "release clears every occupied cell")
	_assert_equal(occupancy.get_entity_at(Vector2i(3, 4)), 0, "released cell has no entity")

	print("GridOccupancy tests passed: 12")
	quit(0)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(value: bool, label: String) -> void:
	if not value:
		_fail("%s: expected true" % label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		_fail("%s: expected false" % label)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
