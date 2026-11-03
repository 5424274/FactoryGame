class_name CameraController
extends Camera2D

# 世界坐标中的移动速度；与渲染帧率无关，按 delta 换算。
@export var move_speed: float = 900.0
# 摄像机允许浏览的世界矩形，必须与 WorldGrid.MAP_SIZE 保持一致。
@export var map_size: Vector2 = Vector2(5120.0, 2880.0)
# 每次滚轮事件的缩放倍率，以及缩放上下限。
@export_range(1.01, 2.0, 0.01) var zoom_step: float = 1.15
@export_range(0.1, 1.0, 0.05) var min_zoom: float = 0.5
@export_range(1.0, 5.0, 0.05) var max_zoom: float = 2.5

# 中键按下到释放之间，摄像机跟随鼠标反向平移。
var _is_middle_mouse_dragging := false


func _ready() -> void:
	# 窗口尺寸变化会改变可见世界范围，因此需要重新计算边界。
	get_viewport().size_changed.connect(_clamp_to_map)
	_clamp_to_map()


func _process(delta: float) -> void:
	# 直接读取按键状态，允许同时按两个键进行斜向移动。
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0

	if direction != Vector2.ZERO:
		global_position += direction.normalized() * move_speed * delta

	_clamp_to_map()


func _unhandled_input(event: InputEvent) -> void:
	# 摄像机只消费中键拖动和滚轮，左/右键留给建筑放置系统。
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _is_middle_mouse_dragging:
		global_position += calculate_drag_offset(event.relative, zoom.x)
		_clamp_to_map()
		get_viewport().set_input_as_handled()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	# 中键拖动不需要区分按下位置，只记录当前是否处于拖动状态。
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_middle_mouse_dragging = event.pressed
		get_viewport().set_input_as_handled()
		return

	if not event.pressed:
		return

	var zoom_factor := 1.0
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_factor = pow(zoom_step, event.factor)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_factor = pow(zoom_step, -event.factor)
	else:
		return

	_zoom_at_mouse(zoom_factor)
	get_viewport().set_input_as_handled()


func calculate_zoom_level(current_zoom: float, zoom_factor: float) -> float:
	# 独立成纯函数，便于测试并保证缩放不会越过上下限。
	return clampf(current_zoom * zoom_factor, min_zoom, max_zoom)


func calculate_drag_offset(screen_relative: Vector2, zoom_level: float) -> Vector2:
	# 屏幕位移需要换算为世界位移；地图跟随鼠标，所以方向取反。
	return -screen_relative / maxf(zoom_level, 0.001)


func is_middle_mouse_dragging() -> bool:
	return _is_middle_mouse_dragging


func _zoom_at_mouse(zoom_factor: float) -> void:
	# 保存缩放前后的鼠标世界坐标，使鼠标下方的地图位置保持不变。
	var mouse_world_before := get_global_mouse_position()
	var next_zoom := calculate_zoom_level(zoom.x, zoom_factor)

	if is_equal_approx(next_zoom, zoom.x):
		return

	zoom = Vector2.ONE * next_zoom
	var mouse_world_after := get_global_mouse_position()
	global_position += mouse_world_before - mouse_world_after
	_clamp_to_map()


func _clamp_to_map() -> void:
	# 以视口半尺寸计算摄像机中心的合法范围，避免显示地图外区域。
	var half_viewport := get_viewport_rect().size * 0.5 / zoom
	var minimum := half_viewport
	var maximum := map_size - half_viewport

	# Keep the camera valid even if a future window becomes larger than the map.
	if minimum.x > maximum.x:
		minimum.x = map_size.x * 0.5
		maximum.x = minimum.x
	if minimum.y > maximum.y:
		minimum.y = map_size.y * 0.5
		maximum.y = minimum.y

	global_position = global_position.clamp(minimum, maximum)
