class_name PlacementResult
extends RefCounted

enum Failure {
	NONE,
	UNKNOWN_DEFINITION,
	OUT_OF_BOUNDS,
	OCCUPIED,
	MINER_REQUIRES_IRON,
	COMMIT_FAILED,
}

var allowed: bool
var failure: Failure
var occupied_cells: Array[Vector2i]
var entity: RefCounted


func _init(
		p_allowed: bool,
		p_failure: Failure = Failure.NONE,
		p_occupied_cells: Array[Vector2i] = []
) -> void:
	allowed = p_allowed
	failure = p_failure
	occupied_cells.assign(p_occupied_cells)
