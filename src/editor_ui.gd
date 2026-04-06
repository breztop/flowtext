extends Control

signal play_requested(config)
signal preview_requested(config)

# Node references (unique names)
@onready var input: TextEdit = %InputText
@onready var segments_box: VBoxContainer = %Segments
@onready var font_size_spin: SpinBox = %FontSizeSpin
@onready var font_option: OptionButton = %FontOption
@onready var scroll_check: CheckBox = %ScrollCheck
@onready var speed_spin: SpinBox = %SpeedSpin
@onready var direction_option: OptionButton = %DirectionOption
@onready var outline_color_btn: ColorPickerButton = %OutlineColorBtn
@onready var outline_size_spin: SpinBox = %OutlineSizeSpin
@onready var bg_color_btn: ColorPickerButton = %BgColorBtn
@onready var fade_check: CheckBox = %FadeCheck
@onready var scale_check: CheckBox = %ScaleCheck
@onready var anim_speed_spin: SpinBox = %AnimSpeedSpin
@onready var glow_check: CheckBox = %GlowCheck
@onready var glow_color_btn: ColorPickerButton = %GlowColorBtn
@onready var glow_intensity_spin: SpinBox = %GlowIntensitySpin
@onready var gradient_check: CheckBox = %GradientCheck
@onready var gradient_start_btn: ColorPickerButton = %GradientStartBtn
@onready var gradient_end_btn: ColorPickerButton = %GradientEndBtn
@onready var gradient_animate_check: CheckBox = %GradientAnimateCheck

# Mode buttons
@onready var mode_support: Button = %SupportModeBtn
@onready var mode_subtitle: Button = %SubtitleModeBtn
@onready var mode_teleprompter: Button = %TeleprompterModeBtn
@onready var mode_danmaku: Button = %DanmakuModeBtn
@onready var mode_custom: Button = %CustomModeBtn

# Page tabs
@onready var input_tab_btn: Button = %InputTabBtn
@onready var settings_tab_btn: Button = %SettingsTabBtn
@onready var segments_tab_btn: Button = %SegmentsTabBtn
@onready var settings_scroll: ScrollContainer = %SettingsScroll
@onready var segment_scroll: ScrollContainer = %SegmentScroll

var _system_fonts: Dictionary = {}
var _config_path: String = "user://flowtext_config.json"
var _current_mode: int = Enum.FlowMode.CUSTOM
var _mode_buttons: Array[Button] = []


func _ready():
	_setup_connections()
	_load_system_fonts()
	_setup_directions()
	_mode_buttons = [mode_support, mode_subtitle, mode_teleprompter, mode_danmaku, mode_custom]
	for i in _mode_buttons.size():
		_mode_buttons[i].pressed.connect(_on_mode_selected.bind(i))
	_select_mode(Enum.FlowMode.CUSTOM)


# ═════════════════════════════════════════
#  Setup
# ═════════════════════════════════════════

func _setup_connections():
	input_tab_btn.pressed.connect(_switch_page.bind(0))
	settings_tab_btn.pressed.connect(_switch_page.bind(1))
	segments_tab_btn.pressed.connect(_on_parse_and_switch)
	%PlayBtn.pressed.connect(_on_play)
	%StopBtn.pressed.connect(_on_stop)
	%PreviewBtn.pressed.connect(_on_preview)
	%SaveBtn.pressed.connect(_on_save)
	%LoadBtn.pressed.connect(_on_load)
	scroll_check.toggled.connect(func(v): speed_spin.editable = v; direction_option.disabled = not v)
	glow_check.toggled.connect(func(v): glow_color_btn.disabled = not v; glow_intensity_spin.editable = v)
	gradient_check.toggled.connect(func(v): gradient_start_btn.disabled = not v; gradient_end_btn.disabled = not v; gradient_animate_check.disabled = not v)


func _setup_directions():
	direction_option.clear()
	direction_option.add_item("← 向左", 0)
	direction_option.add_item("→ 向右", 1)
	direction_option.add_item("↑ 向上", 2)
	direction_option.add_item("↓ 向下", 3)


func _load_system_fonts():
	font_option.clear()
	_system_fonts.clear()
	var fonts := ["Microsoft YaHei", "SimHei", "SimSun", "KaiTi", "Arial", "Impact", "Times New Roman"]
	for i in fonts.size():
		font_option.add_item(fonts[i], i)
		_system_fonts[i] = fonts[i]
	font_option.add_item("默认", fonts.size())


func _get_selected_font() -> Font:
	var id := font_option.get_selected_id()
	if _system_fonts.has(id):
		var sf := SystemFont.new()
		sf.font_names = [_system_fonts[id]]
		return sf
	return null


# ═════════════════════════════════════════
#  Mode System
# ═════════════════════════════════════════

func _on_mode_selected(mode_index: int):
	_select_mode(mode_index)


func _select_mode(mode: int):
	_current_mode = mode
	for i in _mode_buttons.size():
		_mode_buttons[i].button_pressed = (i == mode)
	_apply_mode_defaults(mode)


func _apply_mode_defaults(mode: int):
	match mode:
		Enum.FlowMode.SUPPORT:
			if input.text.strip_edges().is_empty():
				input.text = "加油！"
			font_size_spin.value = 96
			glow_check.button_pressed = true
			glow_color_btn.color = Color(1.0, 0.85, 0.0)
			glow_color_btn.disabled = false
			glow_intensity_spin.value = 2.0
			glow_intensity_spin.editable = true
			fade_check.button_pressed = true
			scale_check.button_pressed = true
			scroll_check.button_pressed = false
			outline_size_spin.value = 4
			outline_color_btn.color = Color(0.2, 0.0, 0.0)
		Enum.FlowMode.SUBTITLE:
			if input.text.strip_edges().is_empty():
				input.text = "字幕文本示例"
			font_size_spin.value = 36
			bg_color_btn.color = Color(0, 0, 0, 0.7)
			outline_size_spin.value = 2
			outline_color_btn.color = Color.BLACK
			scroll_check.button_pressed = false
			fade_check.button_pressed = true
			glow_check.button_pressed = false
			gradient_check.button_pressed = false
		Enum.FlowMode.TELEPROMPTER:
			if input.text.strip_edges().is_empty():
				input.text = "提词器文本...\n第二行\n第三行"
			font_size_spin.value = 42
			scroll_check.button_pressed = true
			speed_spin.value = 40
			speed_spin.editable = true
			direction_option.selected = 2
			direction_option.disabled = false
			fade_check.button_pressed = false
			glow_check.button_pressed = false
		Enum.FlowMode.DANMAKU:
			if input.text.strip_edges().is_empty():
				input.text = "弹幕效果！\n哈哈哈哈"
			font_size_spin.value = 28
			scroll_check.button_pressed = true
			speed_spin.value = 200
			speed_spin.editable = true
			direction_option.disabled = false
			fade_check.button_pressed = false
			glow_check.button_pressed = false


# ═════════════════════════════════════════
#  Page Switching
# ═════════════════════════════════════════

func _switch_page(page: int):
	input_tab_btn.button_pressed = (page == 0)
	settings_tab_btn.button_pressed = (page == 1)
	segments_tab_btn.button_pressed = (page == 2)
	input.visible = (page == 0)
	settings_scroll.visible = (page == 1)
	segment_scroll.visible = (page == 2)


func _on_parse_and_switch():
	_on_parse()
	_switch_page(2)


# ═════════════════════════════════════════
#  Text Parsing
# ═════════════════════════════════════════

func _on_parse():
	for c in segments_box.get_children():
		segments_box.remove_child(c)
		c.queue_free()
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	var lines := text.split("\n")
	for line in lines:
		if line.strip_edges().is_empty():
			_add_newline_segment()
			continue
		var words := line.split(" ", false)
		for word in words:
			_add_segment(word)
		_add_newline_segment()


func _add_newline_segment():
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "[换行]"
	lbl.custom_minimum_size.x = 60
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	hbox.add_child(lbl)
	hbox.set_meta("text", "\n")
	hbox.set_meta("is_newline", true)
	segments_box.add_child(hbox)


func _add_segment(text: String):
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size.x = 60
	hbox.add_child(lbl)
	var color := ColorPickerButton.new()
	color.custom_minimum_size = Vector2(32, 24)
	color.color = Color.WHITE
	hbox.add_child(color)
	var jump := CheckBox.new()
	jump.text = "跳动"
	hbox.add_child(jump)
	segments_box.add_child(hbox)
	hbox.set_meta("text", text + " ")
	hbox.set_meta("color_picker", color)
	hbox.set_meta("jump_check", jump)
	hbox.set_meta("is_newline", false)


# ═════════════════════════════════════════
#  Config Build / Actions
# ═════════════════════════════════════════

func _build_config() -> Dictionary:
	var segs := []
	for hbox in segments_box.get_children():
		if hbox.get_meta("is_newline", false):
			segs.append({"text": "\n", "color": Color.WHITE, "jump": false})
		else:
			segs.append({
				"text": hbox.get_meta("text"),
				"color": hbox.get_meta("color_picker").color,
				"jump": hbox.get_meta("jump_check").button_pressed
			})
	var dir := Vector2.LEFT
	var dir_idx := direction_option.selected
	match dir_idx:
		1: dir = Vector2.RIGHT
		2: dir = Vector2.UP
		3: dir = Vector2.DOWN
	return {
		"segments": segs,
		"font_size": int(font_size_spin.value),
		"font": _get_selected_font(),
		"outline_color": outline_color_btn.color,
		"outline_size": int(outline_size_spin.value),
		"bg_color": bg_color_btn.color,
		"fade_in": fade_check.button_pressed,
		"scale_in": scale_check.button_pressed,
		"anim_speed": anim_speed_spin.value,
		"scroll": scroll_check.button_pressed,
		"scroll_speed": speed_spin.value,
		"scroll_direction": dir,
		"scroll_direction_idx": dir_idx,
		"glow_enabled": glow_check.button_pressed,
		"glow_color": glow_color_btn.color,
		"glow_intensity": glow_intensity_spin.value,
		"glow_size": 0.03,
		"glow_softness": 0.8,
		"gradient_enabled": gradient_check.button_pressed,
		"gradient_start": gradient_start_btn.color,
		"gradient_end": gradient_end_btn.color,
		"gradient_animate": gradient_animate_check.button_pressed,
		"gradient_speed": 1.0,
		"danmaku_mode": _current_mode == Enum.FlowMode.DANMAKU,
		"flow_mode": _current_mode
	}


func _on_play():
	_on_parse()
	play_requested.emit(_build_config())


func _on_preview():
	_on_parse()
	preview_requested.emit(_build_config())


func _on_stop():
	play_requested.emit({"segments": []})


func _on_save():
	var config := _build_config()
	for seg in config.segments:
		if seg.has("color"):
			seg.color = _color_to_array(seg.color)
	config.outline_color = _color_to_array(config.outline_color)
	config.bg_color = _color_to_array(config.bg_color)
	config.glow_color = _color_to_array(config.glow_color)
	config.gradient_start = _color_to_array(config.gradient_start)
	config.gradient_end = _color_to_array(config.gradient_end)
	config.erase("font")
	config.erase("scroll_direction")
	var file := FileAccess.open(_config_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()


func _on_load():
	if not FileAccess.file_exists(_config_path):
		return
	var file := FileAccess.open(_config_path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	file.close()
	var config: Dictionary = json.data
	input.text = ""
	for seg in config.get("segments", []):
		var t: String = seg.get("text", "")
		if t == "\n":
			input.text += "\n"
		else:
			input.text += t.strip_edges() + " "
	font_size_spin.value = config.get("font_size", 48)
	scroll_check.button_pressed = config.get("scroll", false)
	speed_spin.value = config.get("scroll_speed", 100)
	direction_option.selected = config.get("scroll_direction_idx", 0)
	outline_color_btn.color = _array_to_color(config.get("outline_color", [0,0,0,0]))
	outline_size_spin.value = config.get("outline_size", 0)
	bg_color_btn.color = _array_to_color(config.get("bg_color", [0,0,0,0]))
	fade_check.button_pressed = config.get("fade_in", false)
	scale_check.button_pressed = config.get("scale_in", false)
	anim_speed_spin.value = config.get("anim_speed", 1.0)
	glow_check.button_pressed = config.get("glow_enabled", false)
	glow_color_btn.color = _array_to_color(config.get("glow_color", [1,1,1,1]))
	glow_intensity_spin.value = config.get("glow_intensity", 1.0)
	gradient_check.button_pressed = config.get("gradient_enabled", false)
	gradient_start_btn.color = _array_to_color(config.get("gradient_start", [1,0,0,1]))
	gradient_end_btn.color = _array_to_color(config.get("gradient_end", [0,0,1,1]))
	gradient_animate_check.button_pressed = config.get("gradient_animate", false)
	_select_mode(config.get("flow_mode", Enum.FlowMode.CUSTOM))
	_on_parse()


func _color_to_array(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]


func _array_to_color(a: Array) -> Color:
	if a.size() >= 4:
		return Color(a[0], a[1], a[2], a[3])
	return Color.WHITE
