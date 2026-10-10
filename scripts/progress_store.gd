extends Node

const DEFAULT_WING: WingBuild = preload("res://resources/default_wing.tres")
const SAVE_PATH := "user://wingit_progress.cfg"

@export var material_catalog: Array[WingMaterial] = [
	preload("res://resources/materials/canvas.tres"),
	preload("res://resources/materials/bamboo.tres"),
	preload("res://resources/materials/leather.tres"),
	preload("res://resources/materials/carbon_wood.tres"),
]
@export var ability_catalog: Array[WingAbility] = [
	preload("res://resources/abilities/gust_boost.tres"),
	preload("res://resources/abilities/feather_dash.tres"),
	preload("res://resources/abilities/soft_glide.tres"),
]
@export var owned_material_ids: Array[String] = ["canvas", "bamboo"]
@export var unlocked_ability_ids: Array[String] = ["gust_boost", "feather_dash"]
@export_range(0, 999999, 1) var coins: int = 60
@export_range(1, 999, 1) var level_number: int = 1
@export_range(1, 9999, 1) var level_reward: int = 30
@export var wing_build: WingBuild


func _ready() -> void:
	if wing_build == null:
		wing_build = DEFAULT_WING.duplicate(true) as WingBuild
	_load_progress()
	_validate_build()


func get_available_materials(material_type: int) -> Array[WingMaterial]:
	var available: Array[WingMaterial] = []
	for material in material_catalog:
		if material != null \
		and owned_material_ids.has(material.material_id.to_string()) \
		and material.material_type == material_type:
			available.append(material)
	return available


func get_available_abilities() -> Array[WingAbility]:
	var available: Array[WingAbility] = []
	for ability in ability_catalog:
		if ability != null and unlocked_ability_ids.has(ability.ability_id.to_string()):
			available.append(ability)
	return available


func get_wing_upgrade_cost() -> int:
	return 35 + wing_build.upgrade_level * 20


func upgrade_wing() -> bool:
	var cost := get_wing_upgrade_cost()
	if coins < cost:
		return false
	coins -= cost
	wing_build.upgrade_level += 1
	_save_progress()
	return true


func award_level_reward() -> String:
	coins += level_reward
	level_number += 1
	var reward_name := ""

	for material in material_catalog:
		if material != null and not owned_material_ids.has(material.material_id.to_string()):
			owned_material_ids.append(material.material_id.to_string())
			reward_name = material.display_name
			break

	if reward_name.is_empty():
		for ability in ability_catalog:
			if ability != null and not unlocked_ability_ids.has(ability.ability_id.to_string()):
				unlocked_ability_ids.append(ability.ability_id.to_string())
				reward_name = ability.display_name
				break

	_save_progress()
	if reward_name.is_empty():
		return "Your next level is ready."
	return "Unlocked %s." % reward_name


func save_build(build: WingBuild) -> void:
	wing_build = build.duplicate(true) as WingBuild
	_validate_build()
	_save_progress()


func find_material(material_id: String) -> WingMaterial:
	for material in material_catalog:
		if material != null and material.material_id == StringName(material_id):
			return material
	return null


func find_ability(ability_id: String) -> WingAbility:
	for ability in ability_catalog:
		if ability != null and ability.ability_id == StringName(ability_id):
			return ability
	return null


func _validate_build() -> void:
	var skins := get_available_materials(WingMaterial.MaterialType.SKIN)
	var structures := get_available_materials(WingMaterial.MaterialType.STRUCTURE)
	if skins.is_empty() or structures.is_empty():
		return
	if wing_build.skin_material == null \
	or not owned_material_ids.has(wing_build.skin_material.material_id.to_string()):
		wing_build.skin_material = skins[0]
	if wing_build.structure_material == null \
	or not owned_material_ids.has(wing_build.structure_material.material_id.to_string()):
		wing_build.structure_material = structures[0]

	var available_abilities := get_available_abilities()
	while wing_build.action_slots.size() < wing_build.action_slot_count:
		wing_build.action_slots.append(available_abilities[0] if not available_abilities.is_empty() else null)
	while wing_build.action_slots.size() > wing_build.action_slot_count:
		wing_build.action_slots.pop_back()
	for index in range(wing_build.action_slots.size()):
		var ability := wing_build.action_slots[index]
		if ability == null or not unlocked_ability_ids.has(ability.ability_id.to_string()):
			wing_build.action_slots[index] = available_abilities[index % available_abilities.size()] \
				if not available_abilities.is_empty() else null


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	coins = int(config.get_value("progress", "coins", coins))
	level_number = int(config.get_value("progress", "level_number", level_number))
	owned_material_ids = _string_array(
		config.get_value("progress", "owned_material_ids", owned_material_ids)
	)
	unlocked_ability_ids = _string_array(
		config.get_value("progress", "unlocked_ability_ids", unlocked_ability_ids)
	)
	wing_build.span = float(config.get_value("wing", "span", wing_build.span))
	wing_build.size = float(config.get_value("wing", "size", wing_build.size))
	wing_build.accent_color = config.get_value("wing", "accent_color", wing_build.accent_color)
	wing_build.upgrade_level = int(
		config.get_value("wing", "upgrade_level", wing_build.upgrade_level)
	)

	var skin_id: String = config.get_value("wing", "skin_material", "")
	var structure_id: String = config.get_value("wing", "structure_material", "")
	if not skin_id.is_empty():
		wing_build.skin_material = find_material(skin_id)
	if not structure_id.is_empty():
		wing_build.structure_material = find_material(structure_id)

	var saved_actions: Array = config.get_value("wing", "action_slots", [])
	for index in range(mini(saved_actions.size(), wing_build.action_slots.size())):
		wing_build.action_slots[index] = find_ability(str(saved_actions[index]))


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "level_number", level_number)
	config.set_value("progress", "owned_material_ids", owned_material_ids)
	config.set_value("progress", "unlocked_ability_ids", unlocked_ability_ids)
	config.set_value("wing", "span", wing_build.span)
	config.set_value("wing", "size", wing_build.size)
	config.set_value("wing", "accent_color", wing_build.accent_color)
	config.set_value("wing", "upgrade_level", wing_build.upgrade_level)
	config.set_value("wing", "skin_material", wing_build.skin_material.material_id.to_string())
	config.set_value("wing", "structure_material", wing_build.structure_material.material_id.to_string())
	var action_ids: Array[String] = []
	for ability in wing_build.action_slots:
		action_ids.append(ability.ability_id.to_string() if ability != null else "")
	config.set_value("wing", "action_slots", action_ids)
	config.save(SAVE_PATH)


func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result
