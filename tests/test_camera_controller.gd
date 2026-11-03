extends SceneTree

const CameraControllerScript := preload("res://scripts/world/camera_controller.gd")


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var camera := CameraControllerScript.new()
	root.add_child(camera)

	_assert_approx(camera.calculate_zoom_level(1.0, 1.15), 1.15, "normal zoom in")
	_assert_approx(camera.calculate_zoom_level(1.0, 1.0 / 1.15), 1.0 / 1.15, "normal zoom out")
	_assert_approx(camera.calculate_zoom_level(2.4, 2.0), camera.max_zoom, "maximum zoom clamp")
	_assert_approx(camera.calculate_zoom_level(0.6, 0.1), camera.min_zoom, "minimum zoom clamp")

	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	wheel_up.factor = 1.0
	camera._unhandled_input(wheel_up)
	_assert_true(camera.zoom.x > 1.0, "wheel up zooms in")

	var zoom_after_wheel_up := camera.zoom.x
	var wheel_down := InputEventMouseButton.new()
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_down.pressed = true
	wheel_down.factor = 1.0
	camera._unhandled_input(wheel_down)
	_assert_true(camera.zoom.x < zoom_after_wheel_up, "wheel down zooms out")
	_assert_approx(camera.zoom.x, 1.0, "opposite wheel steps cancel")

	_assert_vector_approx(camera.calculate_drag_offset(Vector2(120.0, -60.0), 1.0), Vector2(-120.0, 60.0), "drag direction")
	_assert_vector_approx(camera.calculate_drag_offset(Vector2(120.0, -60.0), 2.0), Vector2(-60.0, 30.0), "drag respects zoom")

	var middle_press := InputEventMouseButton.new()
	middle_press.button_index = MOUSE_BUTTON_MIDDLE
	middle_press.pressed = true
	camera._unhandled_input(middle_press)
	_assert_true(camera.is_middle_mouse_dragging(), "middle press starts dragging")

	camera.global_position = Vector2(2000.0, 1200.0)
	var drag_motion := InputEventMouseMotion.new()
	drag_motion.relative = Vector2(100.0, 50.0)
	camera._unhandled_input(drag_motion)
	_assert_vector_approx(camera.global_position, Vector2(1900.0, 1150.0), "drag moves camera opposite to mouse")

	var middle_release := InputEventMouseButton.new()
	middle_release.button_index = MOUSE_BUTTON_MIDDLE
	middle_release.pressed = false
	camera._unhandled_input(middle_release)
	_assert_false(camera.is_middle_mouse_dragging(), "middle release stops dragging")

	print("CameraController tests passed: 12")
	quit(0)


func _assert_approx(actual: float, expected: float, label: String) -> void:
	if not is_equal_approx(actual, expected):
		_fail("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(value: bool, label: String) -> void:
	if not value:
		_fail("%s: expected true" % label)


func _assert_false(value: bool, label: String) -> void:
	if value:
		_fail("%s: expected false" % label)


func _assert_vector_approx(actual: Vector2, expected: Vector2, label: String) -> void:
	if not actual.is_equal_approx(expected):
		_fail("%s: expected %s, got %s" % [label, expected, actual])


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
