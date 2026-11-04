class_name MainController
extends Node2D

const WorldStateScript := preload("res://scripts/simulation/core/world_state.gd")
const PlacementServiceScript := preload("res://scripts/application/placement_service.gd")
const FactorySimulationScript := preload("res://scripts/simulation/factory_simulation.gd")

var world := WorldStateScript.new()
var placement_service
var factory_simulation


func _enter_tree() -> void:
	# 主场景是唯一组合根；地表在任何 View 的 _ready 前由 WorldState 创建。
	world.initialize_terrain(WorldGrid.GRID_SIZE, 20261104, 18, 4, 9)
	get_node("WorldGrid").configure(world)


func _ready() -> void:
	placement_service = PlacementServiceScript.new(world, WorldGrid.GRID_SIZE)
	factory_simulation = FactorySimulationScript.new(world)
	placement_service.entity_placed.connect(factory_simulation.on_entity_placed)

	var placement := get_node("BuildingPlacement")
	placement.configure(placement_service)
	var view_sync := get_node("EntityViewSynchronizer")
	view_sync.configure(world, placement_service, get_node("WorldGrid"), get_node("Buildings"))
	get_node("FactoryRuntime").configure(world, factory_simulation, get_node("WorldGrid"), get_node("Items"))
