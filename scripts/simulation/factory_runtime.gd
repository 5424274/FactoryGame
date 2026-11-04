class_name FactoryRuntime
extends Node2D

const IRON_ITEM_TEXTURE_PATH := "res://assets/textures/items/iron.png"

@export_range(0.05, 2.0, 0.05) var tick_seconds: float = 0.4

var _world
var _simulation
var _grid: WorldGrid
var _items: Node2D
var _iron_item_texture: Texture2D
var _accumulator := 0.0
var _item_views: Dictionary[int, Sprite2D] = {}


func configure(
		world,
		simulation,
		grid: WorldGrid,
		items: Node2D
) -> void:
	_world = world
	_simulation = simulation
	_grid = grid
	_items = items
	_iron_item_texture = _load_texture_from_source(IRON_ITEM_TEXTURE_PATH)
	_sync_item_views()


func _process(delta: float) -> void:
	if _simulation == null:
		return
	_accumulator += delta
	while _accumulator >= tick_seconds:
		_accumulator -= tick_seconds
		_simulation.advance_tick()
		_sync_item_views()


func _sync_item_views() -> void:
	# 稳定物品 ID 支持增量创建、移动和删除，不再每个 tick 销毁全部 Sprite。
	var visible_item_ids: Dictionary[int, bool] = {}
	for belt_cell in _simulation.get_belt_cells():
		var belt_items: Array = _simulation.get_belt_items(belt_cell)
		for item_index in range(belt_items.size()):
			var item: RefCounted = belt_items[item_index]
			visible_item_ids[item.id] = true
			var sprite := _item_views.get(item.id) as Sprite2D
			if sprite == null:
				sprite = _create_item_view(item.id)
			var offset := Vector2(-6.0, -5.0) if item_index == 0 else Vector2(6.0, 5.0)
			sprite.position = _grid.cell_to_world(belt_cell) + offset

	for item_id in _item_views.keys():
		if visible_item_ids.has(item_id):
			continue
		var sprite := _item_views[item_id]
		if is_instance_valid(sprite):
			sprite.queue_free()
		_item_views.erase(item_id)


func _create_item_view(item_id: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "IronItem_%d" % item_id
	sprite.texture = _iron_item_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.65
	_items.add_child(sprite)
	_item_views[item_id] = sprite
	return sprite


func _load_texture_from_source(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("无法读取素材：%s" % path)
		return null
	return ImageTexture.create_from_image(image)
