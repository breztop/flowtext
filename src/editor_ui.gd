extends Control

signal play_requested(config)
signal preview_requested(config)

@onready var input: TextEdit = $VBox/InputText
@onready var segments_box: VBoxContainer = $VBox/Scroll/Segments
@onready var font_size_spin: SpinBox = $VBox/Grid/FontSizeSpin
@onready var font_option: OptionButton = $VBox/Grid/FontOption
@onready var scroll_check: CheckBox = $VBox/Grid/ScrollCheck
@onready var speed_spin: SpinBox = $VBox/Grid/SpeedSpin
@onready var direction_option: OptionButton = $VBox/Grid/DirectionOption
@onready var outline_color_btn: ColorPickerButton = $VBox/Grid/OutlineColorBtn
@onready var outline_size_spin: SpinBox = $VBox/Grid/OutlineSizeSpin
@onready var bg_color_btn: ColorPickerButton = $VBox/Grid/BgColorBtn
@onready var fade_check: CheckBox = $VBox/Grid/FadeCheck
@onready var scale_check: CheckBox = $VBox/Grid/ScaleCheck
@onready var anim_speed_spin: SpinBox = $VBox/Grid/AnimSpeedSpin
@onready var template_option: OptionButton = $VBox/Grid/TemplateOption
@onready var glow_check: CheckBox = $VBox/Grid/GlowCheck
@onready var glow_color_btn: ColorPickerButton = $VBox/Grid/GlowColorBtn
@onready var glow_intensity_spin: SpinBox = $VBox/Grid/GlowIntensitySpin
@onready var gradient_check: CheckBox = $VBox/Grid/GradientCheck
@onready var gradient_start_btn: ColorPickerButton = $VBox/Grid/GradientStartBtn
@onready var gradient_end_btn: ColorPickerButton = $VBox/Grid/GradientEndBtn
@onready var gradient_animate_check: CheckBox = $VBox/Grid/GradientAnimateCheck
@onready var danmaku_check: CheckBox = $VBox/Grid/DanmakuCheck

var _system_fonts: Dictionary = {}
var _config_path: String = "user://flowtext_config.json"

func _ready():
	$VBox/ParseBtn.pressed.connect(_on_parse)
	$VBox/Bottom/PlayBtn.pressed.connect(_on_play)
	$VBox/Bottom/StopBtn.pressed.connect(_on_stop)
	$VBox/Bottom/PreviewBtn.pressed.connect(_on_preview)
	$VBox/Bottom/SaveBtn.pressed.connect(_on_save)
	$VBox/Bottom/LoadBtn.pressed.connect(_on_load)
	scroll_check.toggled.connect(func(v): speed_spin.editable = v; direction_option.disabled = not v)
	glow_check.toggled.connect(func(v): glow_color_btn.disabled = not v; glow_intensity_spin.editable = v)
	gradient_check.toggled.connect(func(v): gradient_start_btn.disabled = not v; gradient_end_btn.disabled = not v; gradient_animate_check.disabled = not v)
	direction_option.add_item("Left", 0)
	direction_option.add_item("Right", 1)
	direction_option.add_item("Up", 2)
	direction_option.add_item("Down", 3)
	_load_system_fonts()
	_load_templates()

func _load_system_fonts():
	font_option.clear()
	_system_fonts.clear()
	var fonts = ["Arial", "Helvetica", "Times New Roman", "Courier New", "Verdana", "Georgia", "Tahoma", "Impact"]
	for i in fonts.size():
		font_option.add_item(fonts[i], i)
		_system_fonts[i] = fonts[i]
	font_option.add_item("Default", fonts.size())

func _get_selected_font() -> Font:
	var id = font_option.get_selected_id()
	if _system_fonts.has(id):
		var sf = SystemFont.new()
		sf.font_names = [_system_fonts[id]]
		return sf
	return null

func _load_templates():
	template_option.clear()
	template_option.add_item("Custom", 0)
	template_option.add_item("Title", 1)
	template_option.add_item("Marquee", 2)
	template_option.add_item("Subtitle", 3)
	template_option.add_item("Danmaku", 4)
	template_option.add_item("Neon", 5)
	template_option.item_selected.connect(_on_template_selected)

func _on_template_selected(id: int):
	match id:
		1: # Title
			input.text = "Hello World"
			font_size_spin.value = 72
			fade_check.button_pressed = true
			scale_check.button_pressed = true
			scroll_check.button_pressed = false
			danmaku_check.button_pressed = false
		2: # Marquee
			input.text = "Welcome to FlowText"
			font_size_spin.value = 48
			scroll_check.button_pressed = true
			speed_spin.value = 150
			fade_check.button_pressed = false
			scale_check.button_pressed = false
			danmaku_check.button_pressed = false
		3: # Subtitle
			input.text = "This is a subtitle"
			font_size_spin.value = 32
			fade_check.button_pressed = true
			scale_check.button_pressed = false
			scroll_check.button_pressed = false
			danmaku_check.button_pressed = false
		4: # Danmaku
			input.text = "弹幕效果 弹幕弹幕\nDanmaku Effect"
			font_size_spin.value = 28
			scroll_check.button_pressed = true
			speed_spin.value = 200
			danmaku_check.button_pressed = true
			fade_check.button_pressed = false
			scale_check.button_pressed = false
		5: # Neon
			input.text = "NEON"
			font_size_spin.value = 96
			glow_check.button_pressed = true
			glow_color_btn.color = Color.CYAN
			glow_intensity_spin.value = 2.0
			gradient_check.button_pressed = true
			gradient_start_btn.color = Color.MAGENTA
			gradient_end_btn.color = Color.CYAN
			gradient_animate_check.button_pressed = true
			fade_check.button_pressed = true
			scale_check.button_pressed = true
	_on_parse()

func _on_parse():
	for c in segments_box.get_children():
		c.queue_free()
	var text = input.text.strip_edges()
	if text.is_empty():
		return
	var lines = text.split("\n")
	for line in lines:
		if line.strip_edges().is_empty():
			_add_newline_segment()
			continue
		var words = line.split(" ", false)
		for word in words:
			_add_segment(word)
		_add_newline_segment()

func _add_newline_segment():
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "[Enter]"
	lbl.custom_minimum_size.x = 60
	hbox.add_child(lbl)
	hbox.set_meta("text", "\n")
	hbox.set_meta("is_newline", true)
	segments_box.add_child(hbox)

func _add_segment(text: String):
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size.x = 60
	hbox.add_child(lbl)
	var color = ColorPickerButton.new()
	color.custom_minimum_size.x = 40
	hbox.add_child(color)
	var jump = CheckBox.new()
	jump.text = "Jump"
	hbox.add_child(jump)
	segments_box.add_child(hbox)
	hbox.set_meta("text", text + " ")
	hbox.set_meta("color_picker", color)
	hbox.set_meta("jump_check", jump)
	hbox.set_meta("is_newline", false)

func _build_config() -> Dictionary:
	var segs = []
	for hbox in segments_box.get_children():
		if hbox.get_meta("is_newline", false):
			segs.append({"text": "\n", "color": Color.WHITE, "jump": false})
		else:
			segs.append({
				"text": hbox.get_meta("text"),
				"color": hbox.get_meta("color_picker").color,
				"jump": hbox.get_meta("jump_check").button_pressed
			})
	var dir = Vector2.LEFT
	var dir_idx = direction_option.selected
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
		"glow_size": 0.02,
		"glow_softness": 0.5,
		"gradient_enabled": gradient_check.button_pressed,
		"gradient_start": gradient_start_btn.color,
		"gradient_end": gradient_end_btn.color,
		"gradient_animate": gradient_animate_check.button_pressed,
		"gradient_speed": 1.0,
		"danmaku_mode": danmaku_check.button_pressed
	}

func _on_play():
	play_requested.emit(_build_config())

func _on_preview():
	preview_requested.emit(_build_config())

func _on_stop():
	play_requested.emit({"segments": []})

func _on_save():
	var config = _build_config()
	for seg in config.segments:
		if seg.has("color"):
			seg.color = [seg.color.r, seg.color.g, seg.color.b, seg.color.a]
	config.outline_color = [config.outline_color.r, config.outline_color.g, config.outline_color.b, config.outline_color.a]
	config.bg_color = [config.bg_color.r, config.bg_color.g, config.bg_color.b, config.bg_color.a]
	config.glow_color = [config.glow_color.r, config.glow_color.g, config.glow_color.b, config.glow_color.a]
	config.gradient_start = [config.gradient_start.r, config.gradient_start.g, config.gradient_start.b, config.gradient_start.a]
	config.gradient_end = [config.gradient_end.r, config.gradient_end.g, config.gradient_end.b, config.gradient_end.a]
	config.erase("font")
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()

func _on_load():
	if not FileAccess.file_exists(_config_path):
		return
	var file = FileAccess.open(_config_path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	file.close()
	var config = json.data
	input.text = ""
	for seg in config.get("segments", []):
		var t = seg.get("text", "")
		if t == "\n":
			input.text += "\n"
		else:
			input.text += t.strip_edges() + " "
	font_size_spin.value = config.get("font_size", 48)
	scroll_check.button_pressed = config.get("scroll", false)
	speed_spin.value = config.get("scroll_speed", 100)
	direction_option.selected = config.get("scroll_direction_idx", 0)
	var oc = config.get("outline_color", [0,0,0,0])
	outline_color_btn.color = Color(oc[0], oc[1], oc[2], oc[3])
	outline_size_spin.value = config.get("outline_size", 0)
	var bc = config.get("bg_color", [0,0,0,0])
	bg_color_btn.color = Color(bc[0], bc[1], bc[2], bc[3])
	fade_check.button_pressed = config.get("fade_in", false)
	scale_check.button_pressed = config.get("scale_in", false)
	anim_speed_spin.value = config.get("anim_speed", 1.0)
	glow_check.button_pressed = config.get("glow_enabled", false)
	var gc = config.get("glow_color", [1,1,1,1])
	glow_color_btn.color = Color(gc[0], gc[1], gc[2], gc[3])
	glow_intensity_spin.value = config.get("glow_intensity", 1.0)
	gradient_check.button_pressed = config.get("gradient_enabled", false)
	var gs = config.get("gradient_start", [1,0,0,1])
	gradient_start_btn.color = Color(gs[0], gs[1], gs[2], gs[3])
	var ge = config.get("gradient_end", [0,0,1,1])
	gradient_end_btn.color = Color(ge[0], ge[1], ge[2], ge[3])
	gradient_animate_check.button_pressed = config.get("gradient_animate", false)
	danmaku_check.button_pressed = config.get("danmaku_mode", false)
	_on_parse()
