class_name EntityViewSynchronizer
extends Node2D

const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")

const TEST_BUILDING_TEXTURE_PATH := "res://assets/textures/machines/test_building.png"
const CONVEYOR_TEXTURE_PATH := "res://assets/textures/machines/conveyorbelt.png"

var _world
var _placement_service
var _grid: WorldGrid
var _buildings: Node2D
var _views_by_entity_id: Dictionary[int, Sprite2D] = {}
var _test_texture: Texture2D
var _conveyor_texture: Texture2D


func configure(
		world,
		placement_service,
		grid: WorldGrid,
		buildings: Node2D
) -> void:
	_world = world
	_placement_service = placement_service
	_grid = grid
	_buildings = buildings
	_test_texture = _load_texture_from_source(TEST_BUILDING_TEXTURE_PATH)
	_conveyor_texture = _load_texture_from_source(CONVEYOR_TEXTURE_PATH)
	_placement_service.entity_placed.connect(_on_entity_placed)
	rebuild_all()


func rebuild_all() -> void:
	for view in _views_by_entity_id.values():
		if is_instance_valid(view):
			view.queue_free()
	_views_by_entity_id.clear()
	if _world == null:
		return
	for entity_id in _world.get_sorted_entity_ids():
		_create_view(_world.get_entity(entity_id))


func _on_entity_placed(entity: RefCounted) -> void:
	_create_view(entity)


func _create_view(entity: RefCounted) -> void:
	if entity == null or _views_by_entity_id.has(entity.id):
		return
	var sprite := Sprite2D.new()
	sprite.name = "%s_%d" % [String(entity.definition_id).replace(":", "_"), entity.id]
	sprite.texture = _conveyor_texture if entity.definition_id == StructureCatalogScript.CONVEYOR_ID else _test_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = _get_texture_scale(sprite.texture, entity.footprint_size)
	sprite.rotation = float(entity.rotation_quarters) * PI * 0.5
	sprite.position = _get_footprint_world_center(entity.origin, entity.footprint_size)
	sprite.set_meta("entity_id", entity.id)
	_buildings.add_child(sprite)
	_views_by_entity_id[entity.id] = sprite


func _get_footprint_world_center(origin: Vector2i, footprint_size: Vector2i) -> Vector2:
	var top_left := _grid.cell_to_world(origin, false)
	return top_left + Vector2(footprint_size * WorldGrid.CELL_SIZE) * 0.5


func _get_texture_scale(texture: Texture2D, footprint_size: Vector2i) -> Vector2:
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
		return Vector2.ONE
	return Vector2(footprint_size * WorldGrid.CELL_SIZE) / texture.get_size()


func _load_texture_from_source(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("无法读取素材：%s" % path)
		return null
	return ImageTexture.create_from_image(image)
