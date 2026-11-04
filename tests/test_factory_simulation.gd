extends SceneTree

const WorldStateScript := preload("res://scripts/simulation/core/world_state.gd")
const EntityStateScript := preload("res://scripts/simulation/core/entity_state.gd")
const BeltStateScript := preload("res://scripts/simulation/core/belt_state.gd")
const MinerStateScript := preload("res://scripts/simulation/core/miner_state.gd")
const FactorySimulationScript := preload("res://scripts/simulation/factory_simulation.gd")
const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")


func _init() -> void:
	_test_capacity_and_direction()
	_test_miner_and_stable_item_identity()
	_test_deterministic_competition()
	print("FactorySimulation architecture tests passed: 18")
	quit(0)


func _test_capacity_and_direction() -> void:
	var world := WorldStateScript.new()
	_add_belt(world, 1, Vector2i(5, 5), Vector2i.DOWN)
	var simulation := FactorySimulationScript.new(world)
	_assert_true(simulation.can_belt_accept_from(Vector2i(5, 5), Vector2i(5, 4)), "top accepted")
	_assert_false(simulation.can_belt_accept_from(Vector2i(5, 5), Vector2i(5, 6)), "output side rejected")
	_assert_true(simulation.try_insert_item(Vector2i(5, 5), Vector2i(4, 5), FactorySimulationScript.IRON_ITEM_ID), "first item")
	_assert_true(simulation.try_insert_item(Vector2i(5, 5), Vector2i(6, 5), FactorySimulationScript.IRON_ITEM_ID), "second item")
	_assert_false(simulation.try_insert_item(Vector2i(5, 5), Vector2i(5, 4), FactorySimulationScript.IRON_ITEM_ID), "capacity blocks third")
	_assert_equal(simulation.get_belt_item_count(Vector2i(5, 5)), 2, "belt capacity is two")


func _test_miner_and_stable_item_identity() -> void:
	var world := WorldStateScript.new()
	_add_miner(world, 1, Vector2i(3, 3), 100, 0)
	_add_belt(world, 2, Vector2i(4, 5), Vector2i.DOWN)
	_add_belt(world, 3, Vector2i(4, 6), Vector2i.DOWN)
	var simulation := FactorySimulationScript.new(world)
	for _tick in range(3): simulation.advance_tick()
	_assert_equal(world.simulation_tick, 3, "world owns simulation tick")
	_assert_equal(simulation.get_belt_item_count(Vector2i(4, 5)), 1, "miner outputs to lower-right port")
	var first_item_id: int = simulation.get_belt_items(Vector2i(4, 5))[0].id
	simulation.advance_tick()
	_assert_equal(simulation.get_belt_items(Vector2i(4, 6))[0].id, first_item_id, "transport preserves stable item id")
	_assert_equal(world.get_entity(2).id, 2, "belt retains entity identity")


func _test_deterministic_competition() -> void:
	var first_winner := _run_competition([1, 2, 3])
	var second_winner := _run_competition([3, 2, 1])
	_assert_equal(first_winner, 1, "lower entity id wins capacity conflict")
	_assert_equal(second_winner, first_winner, "registration order does not change result")


func _run_competition(registration_order: Array[int]) -> int:
	var world := WorldStateScript.new()
	for entity_id in registration_order:
		if entity_id == 1:
			_add_belt(world, 1, Vector2i(4, 5), Vector2i.RIGHT)
		elif entity_id == 2:
			_add_belt(world, 2, Vector2i(5, 4), Vector2i.DOWN)
		else:
			_add_belt(world, 3, Vector2i(5, 5), Vector2i.DOWN)
	var simulation := FactorySimulationScript.new(world)
	# 目标先占一件，只剩一个容量，两路输入竞争。
	simulation.try_insert_item(Vector2i(5, 5), Vector2i(6, 5), FactorySimulationScript.IRON_ITEM_ID)
	simulation.try_insert_item(Vector2i(4, 5), Vector2i(3, 5), &"source_one")
	simulation.try_insert_item(Vector2i(5, 4), Vector2i(5, 3), &"source_two")
	simulation.advance_tick()
	var items: Array = simulation.get_belt_items(Vector2i(5, 5))
	return 1 if items[1].definition_id == &"source_one" else 2


func _add_belt(world, entity_id: int, origin: Vector2i, direction: Vector2i) -> void:
	var entity := EntityStateScript.new(entity_id, StructureCatalogScript.CONVEYOR_ID, origin, Vector2i.ONE, 0)
	entity.belt = BeltStateScript.new(direction)
	var cells: Array[Vector2i] = [origin]
	_assert_true(world.try_add_entity(entity, cells), "belt entity added")
	world.next_entity_id = maxi(world.next_entity_id, entity_id + 1)


func _add_miner(world, entity_id: int, origin: Vector2i, efficiency: int, rotation: int) -> void:
	var entity := EntityStateScript.new(entity_id, StructureCatalogScript.MINER_ID, origin, Vector2i(2, 2), rotation)
	entity.miner = MinerStateScript.new(efficiency)
	var cells: Array[Vector2i] = [origin, origin + Vector2i.RIGHT, origin + Vector2i.DOWN, origin + Vector2i.ONE]
	_assert_true(world.try_add_entity(entity, cells), "miner entity added")


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected: _fail("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(value: bool, label: String) -> void:
	if not value: _fail("%s: expected true" % label)


func _assert_false(value: bool, label: String) -> void:
	if value: _fail("%s: expected false" % label)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
