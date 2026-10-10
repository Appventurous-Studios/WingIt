extends Control
class_name WingPreview

@export var wing_build: WingBuild
@export var body_color: Color = Color(0.85, 0.88, 0.9, 1.0)


func _draw() -> void:
	var center := size * 0.5
	var wing_color := Color(0.62, 0.69, 0.72, 1.0)
	var bone_color := Color(0.86, 0.77, 0.56, 1.0)
	var scale_factor := 1.0
	if wing_build != null:
		if wing_build.skin_material != null:
			wing_color = wing_build.skin_material.display_color
		if wing_build.structure_material != null:
			bone_color = wing_build.structure_material.display_color
		scale_factor = wing_build.span * wing_build.size

	var half_span := minf(size.x * 0.37, 118.0) * scale_factor
	var chord := minf(size.y * 0.24, 35.0) * wing_build.size if wing_build != null else 35.0
	var left_wing := PackedVector2Array([
		center + Vector2(0.0, -chord * 0.25),
		center + Vector2(-half_span, -chord),
		center + Vector2(-half_span * 0.76, chord * 0.7),
		center + Vector2(0.0, chord * 0.35),
	])
	var right_wing := PackedVector2Array([
		center + Vector2(0.0, -chord * 0.25),
		center + Vector2(half_span, -chord),
		center + Vector2(half_span * 0.76, chord * 0.7),
		center + Vector2(0.0, chord * 0.35),
	])
	draw_colored_polygon(left_wing, wing_color)
	draw_colored_polygon(right_wing, wing_color)
	draw_line(center, center + Vector2(-half_span, -chord * 0.5), bone_color, 4.0)
	draw_line(center, center + Vector2(half_span, -chord * 0.5), bone_color, 4.0)
	draw_circle(center, 15.0, body_color)
