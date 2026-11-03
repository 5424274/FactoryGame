extends SceneTree

const WorldGridScript := preload("res://scripts/world/world_grid.gd")
const BuildingPlacementScript := preload("res://scripts/placement/building_placement.gd")
const BuildingTexture := preload("res://assets/textures/machines/test_building.png")


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var world := Node2D.new()
	root.add_child(world)

	var grid := WorldGridScript.new()
	grid.name = "WorldGrid"
	world.add_child(grid)

	var buildings := Node2D.new()
	buildings.name = "Buildings"
	world.add_child(buildings)

	var placement := BuildingPlacementScript.new()
	placement.grid_path = NodePath("../WorldGrid")
	placement.buildings_path = NodePath("../Buildings")
	placement.building_texture = BuildingTexture
	world.add_child(placement)

	_assert_true(placement.is_placement_active(), "placement starts active")
	_assert_true(placement.can_place_at_cell(Vector2i(4, 3)), "empty in-bounds cell is valid")
	_assert_false(placement.can_place_at_cell(Vector2i(-1, 3)), "negative cell is invalid")
	_assert_false(placement.can_place_at_cell(Vector2i(160, 3)), "outside cell is invalid")
	_assert_true(placement.try_place_at_cell(Vector2i(4, 3)), "first placement succeeds")
	_assert_true(placement.is_cell_occupied(Vector2i(4, 3)), "placed cell becomes occupied")
	_assert_equal(placement.get_occupied_cell_count(), 1, "occupied cell count")
	_assert_equal(buildings.get_child_count(), 1, "building node created")
	_assert_false(placement.try_place_at_cell(Vector2i(4, 3)), "duplicate placement fails")
	_assert_equal(buildings.get_child_count(), 1, "duplicate does not create node")

	placement.set_placement_active(false)
	_assert_false(placement.is_placement_active(), "placement can be cancelled")
	_assert_false(placement.try_place_at_world(Vector2(200.0, 200.0)), "cancelled mode blocks placement")
	placement.set_placement_active(true)
	_assert_true(placement.try_place_at_cell(Vector2i(5, 3)), "placement can resume")

	print("BuildingPlacement tests passed: 13")
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
