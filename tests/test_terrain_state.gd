extends SceneTree

const TerrainStateScript := preload("res://scripts/simulation/terrain_state.gd")


func _init() -> void:
	var first := TerrainStateScript.new()
	var second := TerrainStateScript.new()
	first.generate_iron_fields(Vector2i(160, 90), 20261104, 18, 4, 9)
	second.generate_iron_fields(Vector2i(160, 90), 20261104, 18, 4, 9)

	_assert_true(first.get_iron_cell_count() > 0, "generation creates iron cells")
	_assert_equal(first.get_iron_cell_count(), second.get_iron_cell_count(), "same seed keeps count deterministic")
	_assert_equal(first.get_iron_cells(), second.get_iron_cells(), "same seed keeps layout deterministic")
	for cell in first.get_iron_cells():
		_assert_true(cell.x >= 0 and cell.y >= 0 and cell.x < 160 and cell.y < 90, "iron stays in bounds")
		_assert_equal(first.get_terrain(cell), TerrainStateScript.IRON_ID, "iron cell exposes logical ID")
	_assert_equal(first.get_terrain(Vector2i(-1, -1)), TerrainStateScript.GROUND_ID, "unpainted cell is ground")

	print("TerrainState tests passed")
	quit(0)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(value: bool, label: String) -> void:
	if not value:
		_fail("%s: expected true" % label)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
