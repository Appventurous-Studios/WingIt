extends CharacterBody2D
class_name PlayerController

signal action_used(slot_index: int, ability: WingAbility)

@export_group("Movement")
@export_range(0.0, 2000.0, 10.0) var gravity: float = 780.0
@export_range(100.0, 1200.0, 10.0) var max_fall_speed: float = 560.0
@export_range(50.0, 800.0, 10.0) var min_fall_speed: float = 150.0
@export_range(100.0, 1000.0, 10.0) var tap_horizontal_speed: float = 440.0
@export_range(100.0, 3000.0, 25.0) var horizontal_brake: float = 1250.0
@export var control_screen_width: float = 540.0

@export_group("Gestures")
@export_range(0.05, 1.0, 0.05) var hold_action_threshold: float = 0.35
@export_range(20.0, 400.0, 5.0) var swipe_action_threshold: float = 90.0
@export_range(0.2, 2.0, 0.05) var thrust_speed_multiplier: float = 1.45
@export_range(0.1, 1.0, 0.05) var glide_speed_multiplier: float = 0.45

@export_group("Appearance")
@export var body_color: Color = Color(0.85, 0.88, 0.9, 1.0)
@export var wing_build: WingBuild

var _equipped_actions: Array[WingAbility] = []
var _cooldowns: Array[float] = []
var _input_start_position := Vector2.ZERO
var _input_start_time := 0.0
var _pointer_is_down := false
var _last_steer_direction := 1.0
var _thrust_time_left := 0.0
var _glide_time_left := 0.0
var _dash_time_left := 0.0
var _dash_horizontal_speed := 0.0
var _dexterity_multiplier := 1.0
var _radius := 15.0


func _ready() -> void:
	apply_wing_build(wing_build)
	queue_redraw()


func apply_wing_build(build: WingBuild) -> void:
	wing_build = build
	_equipped_actions.clear()
	if wing_build != null:
		_equipped_actions = wing_build.action_slots.duplicate()
		var stats := wing_build.calculate_stats()
		_dexterity_multiplier = clampf(0.8 + float(stats["dexterity"]) * 0.2, 0.75, 1.35)
	else:
		_dexterity_multiplier = 1.0
	_cooldowns.resize(_equipped_actions.size())
	for index in range(_cooldowns.size()):
		_cooldowns[index] = 0.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	for index in range(_cooldowns.size()):
		_cooldowns[index] = maxf(0.0, _cooldowns[index] - delta)

	_thrust_time_left = maxf(0.0, _thrust_time_left - delta)
	_glide_time_left = maxf(0.0, _glide_time_left - delta)
	_dash_time_left = maxf(0.0, _dash_time_left - delta)

	var fall_multiplier := 1.0
	if _thrust_time_left > 0.0:
		fall_multiplier = thrust_speed_multiplier
	elif _glide_time_left > 0.0:
		fall_multiplier = glide_speed_multiplier

	velocity.y = minf(
		velocity.y + gravity * delta,
		max_fall_speed * fall_multiplier
	)
	if _dash_time_left > 0.0:
		velocity.x = move_toward(
			velocity.x,
			_last_steer_direction * _dash_horizontal_speed,
			horizontal_brake * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_brake * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, _radius + 12.0, control_screen_width - _radius - 12.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_pressed(event.position)
		else:
			_pointer_released(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_pressed(event.position)
		else:
			_pointer_released(event.position)


func _pointer_pressed(position: Vector2) -> void:
	_pointer_is_down = true
	_input_start_position = position
	_input_start_time = Time.get_ticks_msec() / 1000.0


func _pointer_released(position: Vector2) -> void:
	if not _pointer_is_down:
		return
	_pointer_is_down = false
	var held_time := Time.get_ticks_msec() / 1000.0 - _input_start_time
	if _input_start_position.distance_to(position) >= swipe_action_threshold:
		activate_action(0)
	elif held_time >= hold_action_threshold:
		activate_action(1)
	else:
		_last_steer_direction = -1.0 if _input_start_position.x < control_screen_width * 0.5 else 1.0
		velocity.x = _last_steer_direction * tap_horizontal_speed * _dexterity_multiplier


func activate_action(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _equipped_actions.size():
		return
	var ability := _equipped_actions[slot_index]
	if ability == null or _cooldowns[slot_index] > 0.0:
		return

	var cooldown_multiplier := 1.0
	var thrust_multiplier := 1.0
	if wing_build != null:
		var stats := wing_build.calculate_stats()
		cooldown_multiplier = float(stats["cooldown_multiplier"])
		thrust_multiplier = clampf(float(stats["thrust"]) * 0.12, 0.75, 1.6)

	_cooldowns[slot_index] = ability.cooldown * cooldown_multiplier
	match ability.action_type:
		WingAbility.ActionType.THRUST:
			_thrust_time_left = ability.duration
			velocity.y = minf(
				velocity.y + ability.fall_speed_delta * thrust_multiplier,
				max_fall_speed * thrust_speed_multiplier
			)
		WingAbility.ActionType.GLIDE:
			_glide_time_left = ability.duration
			velocity.y = maxf(min_fall_speed, velocity.y - ability.fall_speed_delta)
		WingAbility.ActionType.FEATHER_DASH:
			_dash_time_left = ability.duration
			_dash_horizontal_speed = ability.horizontal_impulse * _dexterity_multiplier
			velocity.x = _last_steer_direction * _dash_horizontal_speed

	action_used.emit(slot_index, ability)


func is_action_ready(slot_index: int) -> bool:
	return slot_index >= 0 \
		and slot_index < _cooldowns.size() \
		and _cooldowns[slot_index] <= 0.0


func _draw() -> void:
	var skin_color := Color(0.62, 0.69, 0.72, 1.0)
	var structure_color := Color(0.86, 0.77, 0.56, 1.0)
	var accent_color := Color(0.9, 0.76, 0.42, 1.0)
	var skin_texture: Texture2D
	var wing_scale := 1.0
	if wing_build != null:
		if wing_build.skin_material != null:
			skin_color = wing_build.skin_material.display_color
			skin_texture = wing_build.skin_material.display_texture
		if wing_build.structure_material != null:
			structure_color = wing_build.structure_material.display_color
		accent_color = wing_build.accent_color
		wing_scale = wing_build.span * wing_build.size

	var half_span := 31.0 * wing_scale
	var wing_shape := PackedVector2Array([
		Vector2(0.0, -8.0),
		Vector2(-half_span, -18.0),
		Vector2(-half_span * 0.76, 11.0),
		Vector2(0.0, 9.0),
		Vector2(half_span * 0.76, 11.0),
		Vector2(half_span, -18.0),
	])
	_draw_wing(wing_shape, skin_color, skin_texture)
	draw_line(Vector2.ZERO, Vector2(-half_span, -12.0), structure_color, 3.0)
	draw_line(Vector2.ZERO, Vector2(half_span, -12.0), structure_color, 3.0)
	draw_line(Vector2(0.0, -7.0), Vector2(0.0, 7.0), accent_color, 3.0)
	draw_circle(Vector2.ZERO, _radius, body_color)
	draw_circle(Vector2(0.0, -4.0), 4.0, Color(0.13, 0.16, 0.18, 1.0))


func _draw_wing(points: PackedVector2Array, color: Color, texture: Texture2D) -> void:
	if texture == null:
		draw_colored_polygon(points, color)
		return

	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	var extent := max_point - min_point
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(Vector2(
			(point.x - min_point.x) / maxf(extent.x, 1.0) * texture.get_width(),
			(point.y - min_point.y) / maxf(extent.y, 1.0) * texture.get_height()
		))
	draw_colored_polygon(points, Color.WHITE, uvs, texture)
