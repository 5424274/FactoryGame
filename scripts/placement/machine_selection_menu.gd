class_name MachineSelectionMenu
extends PanelContainer

@export var placement_path: NodePath

@onready var _placement: BuildingPlacement = get_node(placement_path) as BuildingPlacement
@onready var _buttons: Array[Button] = [
	%Size1Button,
	%Size2Button,
	%Size3Button,
	%MinerButton,
	%ConveyorButton,
]

const STRUCTURE_IDS: Array[StringName] = [
	&"prototype:test_1x1",
	&"prototype:test_2x2",
	&"prototype:test_3x3",
	&"base:iron_miner",
	&"base:conveyor_down",
]


func _ready() -> void:
	for index in range(_buttons.size()):
		_buttons[index].pressed.connect(_select_structure.bind(STRUCTURE_IDS[index]))
	_placement.selected_structure_changed.connect(_update_selected_button)
	_placement.placement_mode_changed.connect(_on_placement_mode_changed)
	_update_selected_button(_placement.get_selected_structure())


func _select_structure(structure_id: StringName) -> void:
	_placement.set_selected_structure(structure_id)
	_placement.set_placement_active(true)


func _update_selected_button(structure_id: StringName) -> void:
	for index in range(_buttons.size()):
		_buttons[index].disabled = _placement.is_placement_active() and STRUCTURE_IDS[index] == structure_id


func _on_placement_mode_changed(active: bool) -> void:
	if active:
		_update_selected_button(_placement.get_selected_structure())
		return
	# 退出放置后解除选中状态，允许再次点击同一个建筑恢复放置。
	for button in _buttons:
		button.disabled = false
