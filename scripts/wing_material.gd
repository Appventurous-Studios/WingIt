extends Resource
class_name WingMaterial

enum MaterialType { SKIN, STRUCTURE }

@export var material_id: StringName = &""
@export var display_name: String = "Untitled material"
@export var material_type: MaterialType = MaterialType.SKIN
@export var display_color: Color = Color(0.7, 0.7, 0.7, 1.0)
@export var display_texture: Texture2D
@export_range(0.05, 3.0, 0.05) var weight_factor: float = 0.5
@export_range(0.1, 3.0, 0.05) var thrust_factor: float = 0.7
@export_range(0.0, 10.0, 0.1) var score_value: float = 1.0
@export_range(0, 9999, 1) var unlock_cost: int = 0
