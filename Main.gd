extends Node2D

const SAVE_PATH := "user://garden_save.json"
const GRID_SIZE := 3
const SEED_COST := 5
const HARVEST_REWARD := 12
const GROW_SECONDS := 25.0

var coins := 25
var seeds := 5
var selected_action := "plant"
var plots: Array = []
var plot_buttons: Array = []
var status_label: Label
var coins_label: Label
var seeds_label: Label
var action_label: Label
var shop_button: Button

func _ready() -> void:
	_load_game()
	_build_ui()
	_refresh_ui()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var background := ColorRect.new()
	background.color = Color("#1d3525")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var main := VBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("separation", 14)
	main.add_theme_constant_override("margin_left", 22)
	main.add_theme_constant_override("margin_right", 22)
	main.add_theme_constant_override("margin_top", 24)
	main.add_theme_constant_override("margin_bottom", 24)
	root.add_child(main)

	var title := Label.new()
	title.text = "🌱 GROW A GARDEN 2"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f5e8b0"))
	main.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Выращивай растения и собирай монеты!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("#c8dfbd"))
	main.add_child(subtitle)

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 22)
	main.add_child(stats)
	coins_label = Label.new()
	seeds_label = Label.new()
	for label in [coins_label, seeds_label]:
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.WHITE)
		stats.add_child(label)

	var field_title := Label.new()
	field_title.text = "ТВОЙ УЧАСТОК"
	field_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field_title.add_theme_font_size_override("font_size", 19)
	field_title.add_theme_color_override("font_color", Color("#f5e8b0"))
	main.add_child(field_title)

	var grid := GridContainer.new()
	grid.columns = GRID_SIZE
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	main.add_child(grid)

	for i in range(GRID_SIZE * GRID_SIZE):
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 104)
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _stylebox("#527b43"))
		button.add_theme_stylebox_override("hover", _stylebox("#668f50"))
		button.add_theme_stylebox_override("pressed", _stylebox("#3f6335"))
		button.pressed.connect(_on_plot_pressed.bind(i))
		grid.add_child(button)
		plot_buttons.append(button)

	var action_title := Label.new()
	action_title.text = "ВЫБЕРИ ДЕЙСТВИЕ"
	action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_title.add_theme_color_override("font_color", Color("#f5e8b0"))
	main.add_child(action_title)

	var actions := GridContainer.new()
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 8)
	main.add_child(actions)
	_add_action_button(actions, "🌰 Сажать", "plant")
	_add_action_button(actions, "💧 Полить", "water")
	_add_action_button(actions, "🧺 Собрать", "harvest")

	shop_button = Button.new()
	shop_button.text = "🛒 Купить 5 семян — 5 монет"
	shop_button.custom_minimum_size.y = 52
	shop_button.add_theme_font_size_override("font_size", 17)
	shop_button.pressed.connect(_buy_seeds)
	main.add_child(shop_button)

	action_label = Label.new()
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.add_theme_color_override("font_color", Color("#f5e8b0"))
	action_label.add_theme_font_size_override("font_size", 16)
	main.add_child(action_label)

	status_label = Label.new()
	status_label.text = "Нажми на пустую грядку, чтобы посадить семя."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("#d9ead3"))
	main.add_child(status_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(spacer)

	var footer := Label.new()
	footer.text = "Прогресс сохраняется автоматически"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color("#9bb79c"))
	main.add_child(footer)

func _stylebox(color_hex: String) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color_hex)
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func _add_action_button(parent: GridContainer, caption: String, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(100, 50)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(_set_action.bind(action))
	parent.add_child(button)

func _set_action(action: String) -> void:
	selected_action = action
	var names := {"plant": "Сажать", "water": "Поливать", "harvest": "Собирать"}
	action_label.text = "Действие: " + names[action]
	_refresh_ui()

func _on_plot_pressed(index: int) -> void:
	var plot: Dictionary = plots[index]
	match selected_action:
		"plant":
			if plot["stage"] != 0:
				_set_status("Эта грядка уже занята!")
			elif seeds <= 0:
				_set_status("Семена закончились. Купи ещё в магазине.")
			else:
				seeds -= 1
				plots[index] = {"stage": 1, "watered": false, "planted_at": Time.get_unix_time_from_system()}
				_set_status("Ты посадил семечко! Оно скоро вырастет 🌱")
		"water":
			if plot["stage"] == 0:
				_set_status("Сначала посади семечко.")
			elif plot["stage"] == 3:
				_set_status("Растение уже готово к сбору!")
			elif plot["watered"]:
				_set_status("Это растение уже полито.")
			else:
				plot["watered"] = true
				plots[index] = plot
				_set_status("Полито! Рост ускорен 💧")
		"harvest":
			if plot["stage"] != 3:
				_set_status("Урожай ещё не готов. Подожди немного.")
			else:
				coins += HARVEST_REWARD
				plots[index] = _empty_plot()
				_set_status("Урожай собран! +12 монет 🪙")
	_refresh_ui()
	_save_game()

func _buy_seeds() -> void:
	if coins < SEED_COST:
		_set_status("Не хватает монет. Собери урожай!")
		return
	coins -= SEED_COST
	seeds += 5
	_set_status("Куплено 5 семян! 🌰")
	_refresh_ui()
	_save_game()

func _process(_delta: float) -> void:
	var changed := false
	var now := Time.get_unix_time_from_system()
	for i in range(plots.size()):
		var plot: Dictionary = plots[i]
		if plot["stage"] > 0 and plot["stage"] < 3:
			var elapsed := float(now - int(plot["planted_at"]))
			var grow_time := GROW_SECONDS * (0.5 if plot["watered"] else 1.0)
			var new_stage := 1
			if elapsed >= grow_time:
				new_stage = 3
			elif elapsed >= grow_time * 0.45:
				new_stage = 2
			if new_stage != int(plot["stage"]):
				plot["stage"] = new_stage
				plots[i] = plot
				changed = true
	if changed:
		_refresh_ui()
		_save_game()

func _empty_plot() -> Dictionary:
	return {"stage": 0, "watered": false, "planted_at": 0}

func _refresh_ui() -> void:
	if coins_label == null:
		return
	coins_label.text = "🪙 %d" % coins
	seeds_label.text = "🌰 %d" % seeds
	var stage_text := ["＋\nПусто", "🌱\nРосток", "🌿\nРастёт", "🥕\nГотово!"]
	for i in range(plot_buttons.size()):
		var plot: Dictionary = plots[i]
		var stage := int(plot["stage"])
		var text := stage_text[stage]
		if stage > 0 and bool(plot["watered"]):
			text += "\n💧"
		plot_buttons[i].text = text
		plot_buttons[i].disabled = false
	shop_button.disabled = coins < SEED_COST
	var names := {"plant": "Сажать", "water": "Поливать", "harvest": "Собирать"}
	action_label.text = "Действие: " + names[selected_action]

func _set_status(message: String) -> void:
	status_label.text = message

func _save_game() -> void:
	var data := {"coins": coins, "seeds": seeds, "plots": plots}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_game() -> void:
	plots.clear()
	for i in range(GRID_SIZE * GRID_SIZE):
		plots.append(_empty_plot())
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", coins))
	seeds = int(parsed.get("seeds", seeds))
	var saved_plots = parsed.get("plots", [])
	for i in range(min(saved_plots.size(), plots.size())):
		if typeof(saved_plots[i]) == TYPE_DICTIONARY:
			plots[i] = saved_plots[i]
