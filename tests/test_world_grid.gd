extends SceneTree

const WorldGridScript := preload("res://scripts/world/world_grid.gd")
const WorldStateScript := preload("res://scripts/simulation/core/world_state.gd")


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var grid := WorldGridScript.new()
	var world := WorldStateScript.new()
	world.initialize_terrain(Vector2i(160, 90), 20261104, 18, 4, 9)
	grid.configure(world)
	root.add_child(grid)

	_assert_equal(grid.world_to_cell(Vector2(0.0, 0.0)), Vector2i(0, 0), "origin cell")
	_assert_equal(grid.world_to_cell(Vector2(31.9, 31.9)), Vector2i(0, 0), "inside first cell")
	_assert_equal(grid.world_to_cell(Vector2(32.0, 32.0)), Vector2i(1, 1), "next cell")
	_assert_equal(grid.world_to_cell(Vector2(-0.1, 0.0)), Vector2i(-1, 0), "negative coordinate")
	_assert_equal(grid.cell_to_world(Vector2i(3, 2)), Vector2(112.0, 80.0), "cell center")
	_assert_equal(grid.get_cell_rect(Vector2i(3, 2)), Rect2(96.0, 64.0, 32.0, 32.0), "cell rectangle")
	_assert_true(grid.is_cell_in_bounds(Vector2i(0, 0)), "minimum bound")
	_assert_true(grid.is_cell_in_bounds(Vector2i(159, 89)), "maximum bound")
	_assert_false(grid.is_cell_in_bounds(Vector2i(160, 89)), "outside x bound")
	_assert_false(grid.is_cell_in_bounds(Vector2i(159, 90)), "outside y bound")
	_assert_true(grid.get_iron_cell_count() > 0, "terrain generation creates iron")

	print("WorldGrid tests passed: 11")
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
