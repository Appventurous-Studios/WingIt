extends Control

const FLIGHT_SCENE: PackedScene = preload("res://scenes/flight.tscn")

var _draft_wing: WingBuild
var _wing_preview: WingPreview
var _draft_stats_label: Label
var _workshop_notice := ""
var _active_flight: FlightController


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show_home()


func _show_home() -> void:
	var page := _new_page("WING IT", "A falling game about building your own wings.")
	var stats := GameProgress.wing_build.calculate_stats()
	var summary := _add_section(page, "YOUR EQUIPPED WING")
	_add_label(summary, "SCORE  %d     LEVEL  %02d" % [stats["score"], GameProgress.level_number], 21)
	_add_label(
		summary,
		"%s skin  ·  %s frame  ·  %d coins" % [
			GameProgress.wing_build.skin_material.display_name,
			GameProgress.wing_build.structure_material.display_name,
			GameProgress.coins,
		],
		15
	)
	_add_button(page, "WING FORGE  ·  BUILD & EQUIP", Callable(self, "_show_workshop"))
	_add_button(
		page,
		"START LEVEL %02d" % GameProgress.level_number,
		Callable(self, "_start_flight")
	)
	_add_label(page, "Greybox prototype · no generated art · designed for portrait play", 13)


func _show_workshop() -> void:
	_draft_wing = GameProgress.wing_build.duplicate(true) as WingBuild
	var page := _new_page("WING FORGE", "Shape your wing, equip two actions, and take it into the next drop.")
	var stats_card := _add_section(page, "DESIGN PREVIEW")
	_wing_preview = WingPreview.new()
	_wing_preview.custom_minimum_size = Vector2(0.0, 164.0)
	_wing_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wing_preview.wing_build = _draft_wing
	stats_card.add_child(_wing_preview)
	_draft_stats_label = _add_label(stats_card, "", 16)
	_refresh_draft_display()
	if not _workshop_notice.is_empty():
		_add_label(page, _workshop_notice, 15)
		_workshop_notice = ""

	var materials_card := _add_section(page, "MATERIALS")
	_add_selector_row(
		materials_card,
		"Skin",
		GameProgress.get_available_materials(WingMaterial.MaterialType.SKIN),
		str(_draft_wing.skin_material.material_id),
		Callable(self, "_on_skin_selected")
	)
	_add_selector_row(
		materials_card,
		"Structure",
		GameProgress.get_available_materials(WingMaterial.MaterialType.STRUCTURE),
		str(_draft_wing.structure_material.material_id),
		Callable(self, "_on_structure_selected")
	)

	var dimensions_card := _add_section(page, "SPAN & SIZE")
	var span_slider := _add_slider_row(dimensions_card, "Span", _draft_wing.span, 0.6, 1.8)
	span_slider.value_changed.connect(func(value: float) -> void:
		_draft_wing.span = value
		_refresh_draft_display()
	)
	var size_slider := _add_slider_row(dimensions_card, "Size", _draft_wing.size, 0.6, 1.8)
	size_slider.value_changed.connect(func(value: float) -> void:
		_draft_wing.size = value
		_refresh_draft_display()
	)
	var color_row := HBoxContainer.new()
	_add_label(color_row, "Accent color", 15)
	var color_picker := ColorPickerButton.new()
	color_picker.color = _draft_wing.accent_color
	color_picker.custom_minimum_size = Vector2(80.0, 44.0)
	color_picker.color_changed.connect(_on_accent_color_changed)
	color_row.add_child(color_picker)
	dimensions_card.add_child(color_row)

	var actions_card := _add_section(page, "ACTION LOADOUT")
	_add_label(actions_card, "Swipe across the screen for slot 1; hold for slot 2.", 14)
	var available_abilities := GameProgress.get_available_abilities()
	for slot_index in range(_draft_wing.action_slot_count):
		var current_ability: WingAbility = null
		if slot_index < _draft_wing.action_slots.size():
			current_ability = _draft_wing.action_slots[slot_index]
		_add_selector_row(
			actions_card,
			"Slot %d" % (slot_index + 1),
			available_abilities,
			str(current_ability.ability_id) if current_ability != null else "",
			Callable(self, "_on_action_selected").bind(slot_index)
		)

	var upgrade_card := _add_section(page, "WING CRAFT")
	_add_label(
		upgrade_card,
		"Craft level %d  ·  %d coins available" % [_draft_wing.upgrade_level, GameProgress.coins],
		15
	)
	_add_button(
		upgrade_card,
		"UPGRADE CRAFT  ·  %d COINS" % GameProgress.get_wing_upgrade_cost(),
		Callable(self, "_upgrade_draft")
	)
	_add_button(page, "EQUIP THIS WING", Callable(self, "_save_and_equip"))
	_add_button(page, "BACK", Callable(self, "_show_home"))


func _start_flight() -> void:
	_clear_page()
	_active_flight = FLIGHT_SCENE.instantiate() as FlightController
	_active_flight.finished.connect(_on_flight_finished)
	add_child(_active_flight)


func _on_flight_finished(success: bool) -> void:
	if is_instance_valid(_active_flight):
		_active_flight.queue_free()
	_active_flight = null
	if success:
		var reward_message := GameProgress.award_level_reward()
		_show_reward(reward_message)
	else:
		_show_failed()


func _show_reward(reward_message: String) -> void:
	var page := _new_page("LEVEL CLEARED", "The wind is yours for another run.")
	var reward_card := _add_section(page, "FLIGHT REWARD")
	_add_label(reward_card, "+%d COINS" % GameProgress.level_reward, 27)
	_add_label(reward_card, reward_message, 17)
	_add_label(
		reward_card,
		"Level %02d unlocked · Wing score %d" % [
			GameProgress.level_number,
			GameProgress.wing_build.calculate_stats()["score"],
		],
		15
	)
	_add_button(page, "UPGRADE / EQUIP WING", Callable(self, "_show_workshop"))
	_add_button(page, "CONTINUE TO LEVEL %02d" % GameProgress.level_number, Callable(self, "_start_flight"))
	_add_button(page, "HOME", Callable(self, "_show_home"))


func _show_failed() -> void:
	var page := _new_page("NOT QUITE", "A barrier caught your wing. Tune your build or try again.")
	_add_label(page, "Your loadout is still equipped.", 16)
	_add_button(page, "RETRY LEVEL", Callable(self, "_start_flight"))
	_add_button(page, "WING FORGE", Callable(self, "_show_workshop"))
	_add_button(page, "HOME", Callable(self, "_show_home"))


func _save_and_equip() -> void:
	GameProgress.save_build(_draft_wing)
	_show_home()


func _upgrade_draft() -> void:
	GameProgress.save_build(_draft_wing)
	if not GameProgress.upgrade_wing():
		_workshop_notice = "Not enough coins for this craft upgrade."
	_show_workshop()


func _on_skin_selected(index: int, option: OptionButton) -> void:
	_draft_wing.skin_material = GameProgress.find_material(str(option.get_item_metadata(index)))
	_refresh_draft_display()


func _on_structure_selected(index: int, option: OptionButton) -> void:
	_draft_wing.structure_material = GameProgress.find_material(str(option.get_item_metadata(index)))
	_refresh_draft_display()


func _on_action_selected(index: int, slot_index: int, option: OptionButton) -> void:
	if slot_index >= _draft_wing.action_slots.size():
		_draft_wing.action_slots.resize(slot_index + 1)
	_draft_wing.action_slots[slot_index] = GameProgress.find_ability(
		str(option.get_item_metadata(index))
	)
	_refresh_draft_display()


func _on_accent_color_changed(color: Color) -> void:
	_draft_wing.accent_color = color
	_refresh_draft_display()


func _refresh_draft_display() -> void:
	if _draft_wing == null:
		return
	var stats := _draft_wing.calculate_stats()
	if _draft_stats_label != null:
		_draft_stats_label.text = "SCORE %d  ·  AREA %.2f  ·  THRUST %.2f  ·  DEXTERITY %.2f" % [
			stats["score"],
			stats["area"],
			stats["thrust"],
			stats["dexterity"],
		]
	if _wing_preview != null:
		_wing_preview.wing_build = _draft_wing
		_wing_preview.queue_redraw()


func _new_page(title: String, subtitle: String) -> VBoxContainer:
	_clear_page()
	var background := ColorRect.new()
	background.color = Color(0.09, 0.11, 0.13, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	_add_label(content, title, 31)
	var subtitle_label := _add_label(content, subtitle, 15)
	subtitle_label.modulate = Color(0.76, 0.8, 0.82, 1.0)
	return content


func _clear_page() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _add_section(parent: Control, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.18, 0.2, 1.0)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title_label := _add_label(column, title, 14)
	title_label.modulate = Color(0.87, 0.76, 0.49, 1.0)
	return column


func _add_label(parent: Control, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _add_selector_row(
	parent: Control,
	title: String,
	items: Array,
	selected_id: String,
	action: Callable
) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := _add_label(row, title, 15)
	label.custom_minimum_size.x = 86.0
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected_index := -1
	for item in items:
		if item == null:
			continue
		var item_id := ""
		if item is WingMaterial:
			item_id = item.material_id.to_string()
		elif item is WingAbility:
			item_id = item.ability_id.to_string()
		option.add_item(item.display_name)
		option.set_item_metadata(option.item_count - 1, item_id)
		if item_id == selected_id:
			selected_index = option.item_count - 1
	if selected_index >= 0:
		option.select(selected_index)
	option.item_selected.connect(action.bind(option))
	row.add_child(option)
	return option


func _add_slider_row(
	parent: Control,
	title: String,
	value: float,
	minimum: float,
	maximum: float
) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := _add_label(row, "%s  %.2f" % [title, value], 15)
	label.custom_minimum_size.x = 112.0
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 38.0
	slider.value_changed.connect(func(new_value: float) -> void:
		label.text = "%s  %.2f" % [title, new_value]
	)
	row.add_child(slider)
	return slider
