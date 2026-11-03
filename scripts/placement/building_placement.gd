class_name BuildingPlacement
extends Node2D

# 外部系统可据此更新建造按钮或提示文字。
signal placement_mode_changed(active: bool)
# 放置成功后发送逻辑网格坐标，而不是像素坐标。
signal building_placed(cell: Vector2i)

# 通过 NodePath 解耦场景结构，避免直接依赖主场景节点名称。
@export var grid_path: NodePath
@export var buildings_path: NodePath
# 当前测试建筑的 32×32 纹理；后续可替换为建筑定义资源。
@export var building_texture: Texture2D

var _grid: WorldGrid
var _buildings: Node2D
var _preview: Sprite2D
var _placement_active := true
var _occupied_cells: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	# 放置系统只负责预览和占用，不负责绘制网格。
	_grid = get_node(grid_path) as WorldGrid
	_buildings = get_node(buildings_path) as Node2D
	_create_preview()
	_update_preview()


func _process(_delta: float) -> void:
	_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	# B/左键/右键/Esc 是建造输入；中键和滚轮由摄像机处理。
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			set_placement_active(true)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			set_placement_active(false)
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
	# 取消模式只隐藏预览，不清除已经放置的建筑或占用记录。
	if _placement_active == active:
		return
	_placement_active = active
	if is_instance_valid(_preview):
		_preview.visible = active
	placement_mode_changed.emit(active)


func is_placement_active() -> bool:
	return _placement_active


func is_cell_occupied(cell: Vector2i) -> bool:
	return _occupied_cells.has(cell)


func can_place_at_cell(cell: Vector2i) -> bool:
	# 1×1 建筑当前只需检查目标格；多格建筑应扩展为占用集合检查。
	return _grid != null and _grid.is_cell_in_bounds(cell) and not is_cell_occupied(cell)


func try_place_at_world(world_position: Vector2) -> bool:
	if not _placement_active or _grid == null:
		return false
	return try_place_at_cell(_grid.world_to_cell(world_position))


func try_place_at_cell(cell: Vector2i) -> bool:
	# 先登记占用再创建显示节点，确保同一帧内不会重复放置。
	if not can_place_at_cell(cell):
		return false

	_occupied_cells[cell] = true
	var building := Sprite2D.new()
	building.name = "TestBuilding_%d_%d" % [cell.x, cell.y]
	building.texture = building_texture
	building.position = _grid.cell_to_world(cell)
	building.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_buildings.add_child(building)
	building_placed.emit(cell)
	_update_preview()
	return true


func get_occupied_cell_count() -> int:
	return _occupied_cells.size()


func _create_preview() -> void:
	# 预览是独立 Sprite，不会被加入 Buildings，也不会被计入占用数量。
	_preview = Sprite2D.new()
	_preview.name = "BuildingPreview"
	_preview.texture = building_texture
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.modulate = Color(0.55, 1.0, 0.55, 0.68)
	_preview.z_index = 10
	add_child(_preview)


func _update_preview() -> void:
	# 每帧将鼠标吸附到网格，并通过颜色反馈当前格是否可用。
	if not is_instance_valid(_preview) or _grid == null:
		return

	if not _placement_active:
		_preview.visible = false
		return

	var cell := _grid.world_to_cell(get_global_mouse_position())
	if not _grid.is_cell_in_bounds(cell):
		_preview.visible = false
		return

	_preview.visible = true
	_preview.global_position = _grid.cell_to_world(cell)
	_preview.modulate = (
		Color(0.55, 1.0, 0.55, 0.68)
		if can_place_at_cell(cell)
		else Color(1.0, 0.3, 0.3, 0.68)
	)
