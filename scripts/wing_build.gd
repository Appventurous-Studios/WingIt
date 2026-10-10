extends Resource
class_name WingBuild

@export var skin_material: WingMaterial
@export var structure_material: WingMaterial
@export var accent_color: Color = Color(0.9, 0.76, 0.42, 1.0)
@export_range(0.5, 1.8, 0.05) var span: float = 1.0
@export_range(0.5, 1.8, 0.05) var size: float = 1.0
@export_range(0, 99, 1) var upgrade_level: int = 0
@export_range(0, 8, 1) var action_slot_count: int = 2
@export var action_slots: Array[WingAbility] = []


func calculate_stats() -> Dictionary:
	var skin_weight := 0.5
	var skin_thrust := 0.5
	var skin_score := 1.0
	var structure_weight := 0.5
	var structure_thrust := 0.7
	var structure_score := 1.0

	if skin_material != null:
		skin_weight = skin_material.weight_factor
		skin_thrust = skin_material.thrust_factor
		skin_score = skin_material.score_value
	if structure_material != null:
		structure_weight = structure_material.weight_factor
		structure_thrust = structure_material.thrust_factor
		structure_score = structure_material.score_value

	var surface_area := maxf(0.1, span * size)
	var mass := surface_area * (skin_weight + structure_weight)
	var thrust := surface_area * (structure_thrust * 0.8 + skin_thrust * 0.2) \
		* (1.0 + upgrade_level * 0.06)
	var dexterity := 1.0 / maxf(0.25, size * (0.55 + mass * 0.45))
	var cooldown_multiplier := clampf(0.55 + size * 0.45 + mass * 0.25, 0.65, 2.5)
	var score := roundi(
		(skin_score + structure_score) * 12.0
		+ surface_area * 18.0
		+ thrust * 6.0
		+ dexterity * 8.0
		+ upgrade_level * 15.0
	)

	return {
		"area": surface_area,
		"mass": mass,
		"thrust": thrust,
		"dexterity": dexterity,
		"cooldown_multiplier": cooldown_multiplier,
		"score": score,
	}
