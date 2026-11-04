extends SceneTree

const WorldStateScript := preload("res://scripts/simulation/core/world_state.gd")
const PlacementServiceScript := preload("res://scripts/application/placement_service.gd")
const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")


func _init() -> void:
	var world := WorldStateScript.new()
	world.initialize_terrain(Vector2i(20, 20), 20261104, 4, 2, 4)
	var service := PlacementServiceScript.new(world, Vector2i(20, 20))

	var first: RefCounted = service.place(StructureCatalogScript.TEST_2_ID, Vector2i(4, 3), 0)
	_assert_true(first.allowed, "2x2 placement succeeds")
	_assert_equal(world.entities.size(), 1, "one authoritative entity created")
	_assert_equal(world.occupancy.get_occupied_cell_count(), 4, "four authoritative cells occupied")
	_assert_equal(first.entity.id, 1, "world allocates stable entity id")
	_assert_equal(world.get_entity_at(Vector2i(5, 4)).id, 1, "occupancy resolves authoritative entity")

	var duplicate: RefCounted = service.place(StructureCatalogScript.TEST_1_ID, Vector2i(5, 4), 0)
	_assert_false(duplicate.allowed, "overlap is rejected")
	_assert_equal(world.entities.size(), 1, "failed placement creates no entity")
	_assert_equal(world.occupancy.get_occupied_cell_count(), 4, "failed placement changes no occupancy")

	var edge: RefCounted = service.place(StructureCatalogScript.TEST_3_ID, Vector2i(18, 18), 0)
	_assert_false(edge.allowed, "out-of-bounds placement rejected")
	_assert_equal(world.next_entity_id, 2, "validation failure consumes no entity id")

	var conveyor: RefCounted = service.place(StructureCatalogScript.CONVEYOR_ID, Vector2i(10, 10), 1)
	_assert_true(conveyor.allowed, "rotated conveyor placement succeeds")
	_assert_equal(conveyor.entity.belt.direction, Vector2i.LEFT, "conveyor capability stores rotated direction")
	_assert_equal(world.entities.size(), 2, "second entity shares same world registry")

	var miner_origin := _find_miner_origin(world, service, Vector2i(20, 20))
	_assert_true(miner_origin != Vector2i(-1, -1), "test map contains miner placement")
	var miner_result: RefCounted = service.place(StructureCatalogScript.MINER_ID, miner_origin, 0)
	_assert_true(miner_result.allowed, "miner with at least one iron cell succeeds")
	_assert_true(miner_result.entity.miner.efficiency_percent > 0, "miner capability stores terrain-derived efficiency")

	_assert_true(world.remove_entity(conveyor.entity.id), "authoritative entity removal succeeds")
	_assert_equal(world.get_entity(conveyor.entity.id), null, "removed entity leaves registry")
	_assert_equal(world.occupancy.get_entity_at(Vector2i(10, 10)), 0, "removed entity releases occupancy")

	print("Placement architecture tests passed: 20")
	quit(0)


func _find_miner_origin(world, service, grid_size: Vector2i) -> Vector2i:
	for y in range(grid_size.y - 1):
		for x in range(grid_size.x - 1):
			var origin := Vector2i(x, y)
			var result: RefCounted = service.validate(StructureCatalogScript.MINER_ID, origin, 0)
			if result.allowed:
				return origin
	return Vector2i(-1, -1)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected: _fail("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(value: bool, label: String) -> void:
	if not value: _fail("%s: expected true" % label)


func _assert_false(value: bool, label: String) -> void:
	if value: _fail("%s: expected false" % label)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
