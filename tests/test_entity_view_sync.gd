extends SceneTree

const WorldStateScript := preload("res://scripts/simulation/core/world_state.gd")
const PlacementServiceScript := preload("res://scripts/application/placement_service.gd")
const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")
const WorldGridScript := preload("res://scripts/world/world_grid.gd")
const ViewSynchronizerScript := preload("res://scripts/presentation/entity_view_synchronizer.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var world := WorldStateScript.new()
	world.initialize_terrain(Vector2i(20, 20), 1, 1, 2, 2)
	var service := PlacementServiceScript.new(world, Vector2i(20, 20))
	var grid := WorldGridScript.new()
	grid.configure(world)
	root.add_child(grid)
	var buildings := Node2D.new()
	root.add_child(buildings)
	var synchronizer := ViewSynchronizerScript.new()
	root.add_child(synchronizer)
	synchronizer.configure(world, service, grid, buildings)

	var result: RefCounted = service.place(StructureCatalogScript.TEST_1_ID, Vector2i(3, 3), 0)
	_assert_true(result.allowed, "authoritative placement succeeds")
	_assert_equal(buildings.get_child_count(), 1, "event creates one view")
	_assert_equal(world.entities.size(), 1, "world owns entity independently")

	synchronizer.rebuild_all()
	await process_frame
	_assert_equal(buildings.get_child_count(), 1, "view rebuild restores one sprite")
	_assert_equal(world.entities.size(), 1, "view rebuild does not change entity state")
	_assert_equal(world.occupancy.get_occupied_cell_count(), 1, "view rebuild does not change occupancy")

	print("EntityViewSynchronizer tests passed: 6")
	quit(0)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, expected, actual])
		quit(1)


func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error("%s: expected true" % label)
		quit(1)
