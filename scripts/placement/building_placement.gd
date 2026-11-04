class_name BuildingPlacement
extends Node2D

const StructureCatalogScript := preload("res://scripts/simulation/core/structure_catalog.gd")

signal placement_mode_changed(active: bool)
signal selected_footprint_changed(footprint_size: Vector2i)
signal selected_structure_changed(structure_id: StringName)

const VALID_PREVIEW_MODULATE := Color(0.55, 1.0, 0.55, 0.68)
const INVALID_PREVIEW_MODULATE := Color(1.0, 1.0, 1.0, 0.18)
const INVALID_PREVIEW_OVERLAY_COLOR := Color(1.0, 0.42, 0.42, 0.78)
const TEST_BUILDING_TEXTURE_PATH := "res://assets/textures/machines/test_building.png"
const CONVEYOR_TEXTURE_PATH := "res://assets/textures/machines/conveyorbelt.png"

@export var grid_path: NodePath

var _grid: WorldGrid
var _placement_service
var _preview: Sprite2D
var _invalid_preview_overlay: Polygon2D
var _placement_active := true
var _selected_structure_id: StringName = StructureCatalogScript.TEST_1_ID
var _selected_rotation_quarters := 0
var _test_texture: Texture2D
var _conveyor_texture: Texture2D


func _ready() -> void:
	_grid = get_node(grid_path) as WorldGrid
	_test_texture = _load_texture_from_source(TEST_BUILDING_TEXTURE_PATH)
	_conveyor_texture = _load_texture_from_source(CONVEYOR_TEXTURE_PATH)
	_create_preview()
	_update_preview_shape()


func configure(placement_service) -> void:
	_placement_service = placement_service
	_update_preview()


func _process(_delta: float) -> void:
	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			set_placement_active(true)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			set_placement_active(false)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and _placement_active:
			rotate_selected_clockwise()
			get_viewport().set_input_as_handled()
		return

	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and _placement_active:
		set_placement_active(false)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_LEFT and _placement_active:
		try_place_at_world(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func set_placement_active(active: bool) -> void:
	if _placement_active == active:
		return
	_placement_active = active
	if is_instance_valid(_preview):
		_preview.visible = active
	placement_mode_changed.emit(active)


func is_placement_active() -> bool:
	return _placement_active


func set_selected_footprint(footprint_size: Vector2i) -> bool:
	match footprint_size:
		Vector2i(1, 1): return set_selected_structure(StructureCatalogScript.TEST_1_ID)
		Vector2i(2, 2): return set_selected_structure(StructureCatalogScript.TEST_2_ID)
		Vector2i(3, 3): return set_selected_structure(StructureCatalogScript.TEST_3_ID)
	return false


func set_selected_structure(structure_id: StringName) -> bool:
	if not StructureCatalogScript.is_valid(structure_id):
		return false
	var previous_footprint := get_selected_footprint()
	var structure_changed := _selected_structure_id != structure_id
	_selected_structure_id = structure_id
	if structure_changed:
		_selected_rotation_quarters = 0
	_update_preview_shape()
	_update_preview()
	if previous_footprint != get_selected_footprint():
		selected_footprint_changed.emit(get_selected_footprint())
	if structure_changed:
		selected_structure_changed.emit(_selected_structure_id)
	return true


func get_selected_structure() -> StringName:
	return _selected_structure_id


func get_selected_footprint() -> Vector2i:
	return StructureCatalogScript.get_rotated_footprint(_selected_structure_id, _selected_rotation_quarters)


func rotate_selected_clockwise() -> void:
	_selected_rotation_quarters = (_selected_rotation_quarters + 1) % 4
	_update_preview_shape()
	_update_preview()


func get_selected_rotation_quarters() -> int:
	return _selected_rotation_quarters


func get_rotated_direction(direction: Vector2i, rotation_quarters: int = -1) -> Vector2i:
	var turns := _selected_rotation_quarters if rotation_quarters < 0 else rotation_quarters
	return StructureCatalogScript.rotate_direction(direction, turns)


func get_footprint_cells(origin: Vector2i, footprint_size: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	var size := get_selected_footprint() if footprint_size == Vector2i.ZERO else footprint_size
	if _placement_service != null:
		return _placement_service.get_footprint_cells(origin, size)
	var cells: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			cells.append(origin + Vector2i(x, y))
	return cells


func world_to_placement_origin(world_position: Vector2) -> Vector2i:
	if _grid == null:
		return WorldGrid.INVALID_CELL
	var footprint := get_selected_footprint()
	var local_position := _grid.to_local(world_position)
	return Vector2i(
		_center_axis_to_origin(local_position.x, footprint.x),
		_center_axis_to_origin(local_position.y, footprint.y)
	)


func can_place_at_cell(origin: Vector2i) -> bool:
	return _placement_service != null and _placement_service.validate(
		_selected_structure_id, origin, _selected_rotation_quarters
	).allowed


func try_place_at_world(world_position: Vector2) -> bool:
	return _placement_active and try_place_at_cell(world_to_placement_origin(world_position))


func try_place_at_cell(origin: Vector2i) -> bool:
	if not _placement_active or _placement_service == null:
		return false
	var result: RefCounted = _placement_service.place(
		_selected_structure_id, origin, _selected_rotation_quarters
	)
	_update_preview()
	return result.allowed


func _create_preview() -> void:
	_preview = Sprite2D.new()
	_preview.name = "BuildingPreview"
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.self_modulate = VALID_PREVIEW_MODULATE
	_preview.z_index = 10
	add_child(_preview)
	_invalid_preview_overlay = Polygon2D.new()
	_invalid_preview_overlay.name = "InvalidOverlay"
	_invalid_preview_overlay.color = INVALID_PREVIEW_OVERLAY_COLOR
	_invalid_preview_overlay.z_index = 1
	_invalid_preview_overlay.visible = false
	_preview.add_child(_invalid_preview_overlay)


func _update_preview_shape() -> void:
	if not is_instance_valid(_preview) or not is_instance_valid(_invalid_preview_overlay):
		return
	var footprint := get_selected_footprint()
	_preview.texture = _get_selected_texture()
	_preview.scale = _get_texture_scale(_preview.texture, footprint)
	_preview.rotation = float(_selected_rotation_quarters) * PI * 0.5
	var half_texture := _preview.texture.get_size() * 0.5 if _preview.texture != null else Vector2.ONE * 16.0
	_invalid_preview_overlay.polygon = PackedVector2Array([
		Vector2(-half_texture.x, -half_texture.y), Vector2(half_texture.x, -half_texture.y),
		Vector2(half_texture.x, half_texture.y), Vector2(-half_texture.x, half_texture.y),
	])


func _update_preview() -> void:
	if not is_instance_valid(_preview) or _grid == null or _placement_service == null:
		return
	if not _placement_active:
		_preview.visible = false
		return
	var mouse_world_position := get_global_mouse_position()
	if not _grid.is_cell_in_bounds(_grid.world_to_cell(mouse_world_position)):
		_preview.visible = false
		return
	var origin := world_to_placement_origin(mouse_world_position)
	var footprint := get_selected_footprint()
	_preview.visible = true
	_preview.global_position = _grid.cell_to_world(origin, false) + Vector2(footprint * WorldGrid.CELL_SIZE) * 0.5
	var can_place := can_place_at_cell(origin)
	_preview.self_modulate = VALID_PREVIEW_MODULATE if can_place else INVALID_PREVIEW_MODULATE
	_invalid_preview_overlay.visible = not can_place


func _center_axis_to_origin(local_axis_position: float, footprint_length: int) -> int:
	var grid_position := local_axis_position / WorldGrid.CELL_SIZE
	var half_length := floori(float(footprint_length) * 0.5)
	return (roundi(grid_position) if footprint_length % 2 == 0 else floori(grid_position)) - half_length


func _get_selected_texture() -> Texture2D:
	return _conveyor_texture if _selected_structure_id == StructureCatalogScript.CONVEYOR_ID else _test_texture


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
