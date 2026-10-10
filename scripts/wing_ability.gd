extends Resource
class_name WingAbility

enum ActionType { THRUST, GLIDE, FEATHER_DASH }

@export var ability_id: StringName = &""
@export var display_name: String = "Untitled action"
@export_multiline var description: String = ""
@export var action_type: ActionType = ActionType.THRUST
@export_range(0.0, 1000.0, 10.0) var fall_speed_delta: float = 240.0
@export_range(0.0, 1000.0, 10.0) var horizontal_impulse: float = 120.0
@export_range(0.1, 10.0, 0.1) var duration: float = 0.8
@export_range(0.0, 30.0, 0.1) var cooldown: float = 2.5
@export var display_color: Color = Color(0.6, 0.8, 1.0, 1.0)
