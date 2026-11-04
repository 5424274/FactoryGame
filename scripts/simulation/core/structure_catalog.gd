class_name StructureCatalog
extends RefCounted

const TEST_1_ID := &"prototype:test_1x1"
const TEST_2_ID := &"prototype:test_2x2"
const TEST_3_ID := &"prototype:test_3x3"
const MINER_ID := &"base:iron_miner"
const CONVEYOR_ID := &"base:conveyor_down"


static func is_valid(definition_id: StringName) -> bool:
	return definition_id in [TEST_1_ID, TEST_2_ID, TEST_3_ID, MINER_ID, CONVEYOR_ID]


static func get_base_footprint(definition_id: StringName) -> Vector2i:
	match definition_id:
		TEST_1_ID, CONVEYOR_ID:
			return Vector2i(1, 1)
		TEST_2_ID, MINER_ID:
			return Vector2i(2, 2)
		TEST_3_ID:
			return Vector2i(3, 3)
	return Vector2i.ZERO


static func get_rotated_footprint(definition_id: StringName, rotation_quarters: int) -> Vector2i:
	var size := get_base_footprint(definition_id)
	if posmod(rotation_quarters, 2) == 1:
		return Vector2i(size.y, size.x)
	return size


static func rotate_direction(direction: Vector2i, rotation_quarters: int) -> Vector2i:
	var result := direction
	for _turn in range(posmod(rotation_quarters, 4)):
		result = Vector2i(-result.y, result.x)
	return result


static func rotate_local_cell(cell: Vector2i, footprint_size: Vector2i, rotation_quarters: int) -> Vector2i:
	var result := cell
	var current_size := footprint_size
	for _turn in range(posmod(rotation_quarters, 4)):
		result = Vector2i(current_size.y - 1 - result.y, result.x)
		current_size = Vector2i(current_size.y, current_size.x)
	return result
