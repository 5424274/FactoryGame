class_name WorldGrid
extends Node2D

# 鼠标悬停单元格改变时通知预览、UI 等其他系统。
signal hovered_cell_changed(cell: Vector2i)

# 逻辑网格常量：每格 32 像素，地图共 160×90 格。
const CELL_SIZE := 32
const GRID_SIZE := Vector2i(160, 90)
const MAP_SIZE := Vector2(GRID_SIZE * CELL_SIZE)
# 用于表示鼠标当前不在地图有效范围内。
const INVALID_CELL := Vector2i(-1, -1)
const IRON_TEXTURE_PATH := "res://assets/textures/terrain/iron_block.png"

@export var iron_texture: Texture2D

var hovered_cell: Vector2i = INVALID_CELL
var _world


func configure(world) -> void:
	_world = world


func _ready() -> void:
	_load_iron_texture_if_needed()
	queue_redraw()


func _process(_delta: float) -> void:
	# 网格本身负责悬停检测，建筑放置系统只消费坐标 API。
	var next_hovered_cell := world_to_cell(get_global_mouse_position())
	if not is_cell_in_bounds(next_hovered_cell):
		next_hovered_cell = INVALID_CELL

	if next_hovered_cell != hovered_cell:
		hovered_cell = next_hovered_cell
		hovered_cell_changed.emit(hovered_cell)
		queue_redraw()


func world_to_cell(world_position: Vector2) -> Vector2i:
	# 将世界坐标转换为左上角起始的整数网格坐标。
	var local_position := to_local(world_position)
	return Vector2i(floori(local_position.x / CELL_SIZE), floori(local_position.y / CELL_SIZE))


func cell_to_world(cell: Vector2i, centered: bool = true) -> Vector2:
	# 将网格坐标转换回世界坐标；建筑默认放在单元格中心。
	var local_position := Vector2(cell * CELL_SIZE)
	if centered:
		local_position += Vector2.ONE * CELL_SIZE * 0.5
	return to_global(local_position)


func is_cell_in_bounds(cell: Vector2i) -> bool:
	# 所有建筑放置和地图访问都应先经过此边界判断。
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y


func get_cell_rect(cell: Vector2i) -> Rect2:
	# 返回单元格左上角坐标和尺寸，用于高亮、碰撞及放置预览。
	return Rect2(Vector2(cell * CELL_SIZE), Vector2.ONE * CELL_SIZE)


func snap_world_to_cell_center(world_position: Vector2) -> Vector2:
	# 将任意世界位置吸附到合法单元格中心；越界位置保持原值。
	var cell := world_to_cell(world_position)
	if not is_cell_in_bounds(cell):
		return world_position
	return cell_to_world(cell)


func get_terrain_id(cell: Vector2i) -> StringName:
	return _world.terrain.get_terrain(cell) if _world != null else &"base:ground"


func is_iron_cell(cell: Vector2i) -> bool:
	return _world != null and _world.terrain.is_iron(cell)


func get_iron_cell_count() -> int:
	return _world.terrain.get_iron_cell_count() if _world != null else 0


func _load_iron_texture_if_needed() -> void:
	if iron_texture != null:
		return
	if ResourceLoader.exists(IRON_TEXTURE_PATH, "Texture2D"):
		iron_texture = load(IRON_TEXTURE_PATH) as Texture2D
		return
	# 源文件尚未生成 Godot 导入缓存时也能显示；这只属于表现层，不进入 TerrainState。
	var image := Image.load_from_file(IRON_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_error("无法读取铁矿贴图：%s" % IRON_TEXTURE_PATH)
		return
	iron_texture = ImageTexture.create_from_image(image)


func _draw() -> void:
	# 绘制只属于世界表现层，不改变网格的逻辑占用状态。
	# 浅灰地面保持中性，便于后续辨认建筑、传送带和放置提示。
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("d6d8dc"), true)
	_draw_terrain()
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("83d6ff"), false, 6.0)
	_draw_hovered_cell()


func _draw_terrain() -> void:
	if iron_texture == null:
		return
	# 贴图只是 TerrainState 的表现结果，网格线随后覆盖在贴图上保持格子清晰。
	if _world == null:
		return
	for cell in _world.terrain.get_iron_cells():
		draw_texture_rect(iron_texture, get_cell_rect(cell), false)


func _draw_hovered_cell() -> void:
	if not is_cell_in_bounds(hovered_cell):
		return

	var cell_rect := get_cell_rect(hovered_cell)
	draw_rect(cell_rect, Color(0.25, 0.82, 1.0, 0.28), true)
	draw_rect(cell_rect, Color("f2fbff"), false, 2.0)
