extends Node2D
class_name FlightController

signal finished(success: bool)

@export_group("Level")
@export_range(320.0, 1200.0, 10.0) var world_width: float = 540.0
@export_range(500.0, 5000.0, 50.0) var goal_distance: float = 1900.0
@export_range(24.0, 120.0, 4.0) var obstacle_thickness: float = 44.0
@export_range(80.0, 400.0, 10.0) var obstacle_gap_width: float = 190.0
@export var obstacle_distances: Array[float] = [430.0, 820.0, 1210.0, 1600.0]
@export var obstacle_gap_centers: Array[float] = [115.0, 425.0, 245.0, 380.0]
@export var lane_color: Color = Color(0.14, 0.17, 0.19, 1.0)
@export var obstacle_color: Color = Color(0.43, 0.47, 0.5, 1.0)
@export var goal_color: Color = Color(0.85, 0.72, 0.36, 1.0)

@onready var player: PlayerController = $Player

var _finished := false
var _altitude_label: Label
var _hazard_radius := 15.0


func _ready() -> void:
	player.apply_wing_build(GameProgress.wing_build)
	_build_hud()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _finished:
		return
	if _altitude_label != null:
		_altitude_label.text = "LEVEL %02d     DROP %04d m" % [
			GameProgress.level_number,
			maxi(0, roundi(player.position.y)),
		]

	for index in range(mini(obstacle_distances.size(), obstacle_gap_centers.size())):
		var obstacle_y := obstacle_distances[index]
		if player.position.y >= obstacle_y - _hazard_radius \
		and player.position.y <= obstacle_y + obstacle_thickness + _hazard_radius:
			var gap_left := obstacle_gap_centers[index] - obstacle_gap_width * 0.5
			var gap_right := obstacle_gap_centers[index] + obstacle_gap_width * 0.5
			if player.position.x < gap_left + _hazard_radius \
			or player.position.x > gap_right - _hazard_radius:
				_finish(false)
				return

	if player.position.y >= goal_distance:
		_finish(true)


func _draw() -> void:
	var upper_edge := -800.0
	var lower_edge := goal_distance + 500.0
	draw_rect(
		Rect2(Vector2(0.0, upper_edge), Vector2(world_width, lower_edge - upper_edge)),
		Color(0.09, 0.11, 0.13, 1.0)
	)
	draw_rect(
		Rect2(Vector2(20.0, upper_edge), Vector2(world_width - 40.0, lower_edge - upper_edge)),
		lane_color
	)
	for marker_y in range(-760, roundi(lower_edge), 100):
		draw_line(
			Vector2(26.0, marker_y),
			Vector2(world_width - 26.0, marker_y),
			Color(0.23, 0.26, 0.28, 1.0),
			1.0
		)
	draw_line(Vector2(20.0, upper_edge), Vector2(20.0, lower_edge), obstacle_color, 5.0)
	draw_line(
		Vector2(world_width - 20.0, upper_edge),
		Vector2(world_width - 20.0, lower_edge),
		obstacle_color,
		5.0
	)

	for index in range(mini(obstacle_distances.size(), obstacle_gap_centers.size())):
		var obstacle_y := obstacle_distances[index]
		var gap_left := obstacle_gap_centers[index] - obstacle_gap_width * 0.5
		var gap_right := obstacle_gap_centers[index] + obstacle_gap_width * 0.5
		draw_rect(
			Rect2(Vector2(20.0, obstacle_y), Vector2(maxf(0.0, gap_left - 20.0), obstacle_thickness)),
			obstacle_color
		)
		draw_rect(
			Rect2(
				Vector2(gap_right, obstacle_y),
				Vector2(maxf(0.0, world_width - 20.0 - gap_right), obstacle_thickness)
			),
			obstacle_color
		)
		draw_line(
			Vector2(gap_left, obstacle_y + obstacle_thickness * 0.5),
			Vector2(gap_right, obstacle_y + obstacle_thickness * 0.5),
			goal_color,
			2.0
		)

	draw_rect(
		Rect2(Vector2(20.0, goal_distance), Vector2(world_width - 40.0, 18.0)),
		goal_color
	)


func _finish(success: bool) -> void:
	if _finished:
		return
	_finished = true
	set_physics_process(false)
	finished.emit(success)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 24)
	canvas.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	_altitude_label = Label.new()
	_altitude_label.add_theme_font_size_override("font_size", 20)
	column.add_child(_altitude_label)

	var instruction := Label.new()
	instruction.text = "TAP LEFT / RIGHT TO STEER\nSWIPE TO BOOST  ·  HOLD TO USE SLOT 2"
	instruction.add_theme_font_size_override("font_size", 14)
	instruction.modulate = Color(0.82, 0.86, 0.88, 1.0)
	column.add_child(instruction)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var quit_button := Button.new()
	quit_button.text = "QUIT LEVEL"
	quit_button.custom_minimum_size.y = 52.0
	quit_button.pressed.connect(_finish.bind(false))
	column.add_child(quit_button)
