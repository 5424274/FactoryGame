class_name MinerState
extends RefCounted

var progress_work := 0
var efficiency_percent: int


func _init(p_efficiency_percent: int) -> void:
	efficiency_percent = clampi(p_efficiency_percent, 0, 100)
