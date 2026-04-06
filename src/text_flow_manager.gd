extends Control
class_name TextFlowManager

signal signal_setting_warning(message: String)

@export var character_scene: PackedScene

var scroll_speed: float = 100.0
var is_scrolling: bool = false
var scroll_direction: Vector2 = Vector2.LEFT
var total_width: float = 0.0
var total_height: float = 0.0
var characters: Array[TextCharacter] = []
var _danmaku_mode: bool = false
var _flow_mode: int = Enum.FlowMode.CUSTOM

@onready var container: Control = $TextContainer
@onready var bg_panel: Panel = $BgPanel


func _ready():
	if not character_scene:
		character_scene = preload("res://src/text_character.tscn")


func _process(delta):
	if not is_scrolling or characters.size() == 0:
		return

	if _danmaku_mode:
		_process_danmaku(delta)
		return

	container.position += scroll_direction * scroll_speed * delta
	var vp = get_viewport_rect().size
	if scroll_direction.x < 0 and container.position.x < -total_width:
		container.position.x = vp.x
	elif scroll_direction.x > 0 and container.position.x > vp.x:
		container.position.x = -total_width
	if scroll_direction.y < 0 and container.position.y < -total_height:
		container.position.y = vp.y
	elif scroll_direction.y > 0 and container.position.y > vp.y:
		container.position.y = -total_height


func _process_danmaku(delta: float):
	var vp = get_viewport_rect().size
	for ch in characters:
		if is_instance_valid(ch):
			ch.position.x -= scroll_speed * delta
			if ch.position.x < -200:
				ch.position.x = vp.x + randf_range(0, 200)
				ch.original_pos.x = ch.position.x


func stop():
	is_scrolling = false
	_danmaku_mode = false
	for ch in characters:
		if is_instance_valid(ch):
			ch.stop_animations()
	# remove_child 立即从场景树移除（不再渲染），queue_free 安全释放
	# 避免 queue_free 延迟导致新旧节点同帧共存出现"重影"
	var children := container.get_children()
	for child in children:
		container.remove_child(child)
		child.queue_free()
	characters.clear()
	if bg_panel:
		bg_panel.visible = false
	container.position = Vector2.ZERO


func generate_flow(config: Dictionary):
	stop()

	_flow_mode = config.get("flow_mode", Enum.FlowMode.CUSTOM)
	_danmaku_mode = config.get("danmaku_mode", false) or _flow_mode == Enum.FlowMode.DANMAKU

	var segments = config.get("segments", [])
	if segments.is_empty():
		return

	var font_size = config.get("font_size", 48)
	var font = config.get("font", null)
	var outline_color = config.get("outline_color", Color.TRANSPARENT)
	var outline_size = config.get("outline_size", 0)
	var bg_color = config.get("bg_color", Color.TRANSPARENT)
	var do_fade = config.get("fade_in", false)
	var do_scale = config.get("scale_in", false)
	var anim_speed = config.get("anim_speed", 1.0)
	var do_scroll = config.get("scroll", false)
	var speed = config.get("scroll_speed", 100.0)
	var direction = config.get("scroll_direction", Vector2.LEFT)

	var glow_enabled = config.get("glow_enabled", false)
	var glow_color = config.get("glow_color", Color.WHITE)
	var glow_intensity = config.get("glow_intensity", 1.5)
	var glow_size = config.get("glow_size", 0.03)
	var glow_softness = config.get("glow_softness", 0.8)

	var gradient_enabled = config.get("gradient_enabled", false)
	var gradient_start = config.get("gradient_start", Color.RED)
	var gradient_end = config.get("gradient_end", Color.BLUE)
	var gradient_animate = config.get("gradient_animate", false)
	var gradient_speed = config.get("gradient_speed", 1.0)

	var vp_size = get_viewport_rect().size
	var x = 0.0
	var y = 0.0
	var max_line_width = 0.0
	var char_index = 0

	# Mode-specific overrides
	match _flow_mode:
		Enum.FlowMode.TELEPROMPTER:
			do_scroll = true
			direction = Vector2.UP
			if speed > 80:
				speed = 50.0

	if _danmaku_mode:
		x = vp_size.x + randf_range(0, 300)
		y = randf_range(50, vp_size.y - 100)

	for segment in segments:
		var seg_text = segment.get("text", "")
		var color = segment.get("color", Color.WHITE)
		var jump = segment.get("jump", false)

		for ch in seg_text:
			if ch == "\n":
				if _danmaku_mode:
					y += font_size * 1.5
					if y > vp_size.y - 50:
						y = 50
					x = vp_size.x + randf_range(0, 200)
				else:
					max_line_width = max(max_line_width, x)
					x = 0
					y += font_size * 1.3
				continue

			if ch == " ":
				x += _get_char_width(" ", font_size, font)
				continue

			var node = character_scene.instantiate() as TextCharacter
			container.add_child(node)
			characters.append(node)
			node.setup(ch, font_size, color, font, outline_color, outline_size)
			node.is_jumping = jump

			if glow_enabled:
				node.apply_glow(glow_color, glow_intensity, glow_size, glow_softness)

			if gradient_enabled:
				node.apply_gradient(gradient_start, gradient_end, gradient_animate, gradient_speed)

			var w = _get_char_width(ch, font_size, font)
			node.position = Vector2(x, y)
			node.original_pos = node.position
			x += w

			if _danmaku_mode:
				node.position.y += randf_range(-10, 10)
				node.original_pos.y = node.position.y

			if do_fade:
				node.do_fade_in(char_index * 0.03 / anim_speed, 0.3 / anim_speed)

			if do_scale:
				node.do_scale_in(char_index * 0.03 / anim_speed, 0.3 / anim_speed)

			if jump:
				_start_jump(node, anim_speed)

			char_index += 1

		x += font_size * (0.5 if _danmaku_mode else 0.3)

	max_line_width = max(max_line_width, x)
	total_width = max_line_width
	total_height = y + font_size

	_apply_mode_layout(vp_size)
	_setup_background(bg_color)

	scroll_speed = speed
	scroll_direction = direction
	is_scrolling = do_scroll


func _apply_mode_layout(vp_size: Vector2):
	match _flow_mode:
		Enum.FlowMode.SUPPORT:
			var cx = (vp_size.x - total_width) / 2.0
			var cy = (vp_size.y - total_height) / 2.0
			container.position = Vector2(cx, cy)
		Enum.FlowMode.SUBTITLE:
			var cx = (vp_size.x - total_width) / 2.0
			var cy = vp_size.y - total_height - 50
			container.position = Vector2(cx, cy)
		Enum.FlowMode.TELEPROMPTER:
			var cx = (vp_size.x - total_width) / 2.0
			container.position = Vector2(cx, vp_size.y * 0.1)
		Enum.FlowMode.DANMAKU:
			pass
		_:
			container.position = Vector2(20, 20)


func _setup_background(bg_color: Color):
	if not bg_panel:
		return
	if bg_color.a < 0.01:
		bg_panel.visible = false
		return
	bg_panel.visible = true
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	bg_panel.add_theme_stylebox_override("panel", style)

	match _flow_mode:
		Enum.FlowMode.SUBTITLE:
			var vp_size = get_viewport_rect().size
			bg_panel.position = Vector2(0, container.position.y - 15)
			bg_panel.size = Vector2(vp_size.x, total_height + 30)
			var sub_style = StyleBoxFlat.new()
			sub_style.bg_color = bg_color
			bg_panel.add_theme_stylebox_override("panel", sub_style)
		_:
			bg_panel.position = container.position + Vector2(-20, -15)
			bg_panel.size = Vector2(total_width + 40, total_height + 30)


func _get_char_width(ch: String, font_size: int, font: Font) -> float:
	if font:
		return font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# 默认字体：CJK 字符近似全角，ASCII 约半角
	var code := ch.unicode_at(0)
	if code > 0x2E80:
		return font_size * 1.0
	return font_size * 0.6


func _start_jump(node: TextCharacter, speed: float = 1.0):
	await get_tree().create_timer(randf() / speed).timeout
	while is_instance_valid(node) and node.is_jumping:
		node.do_jump()
		await get_tree().create_timer(0.8 / speed).timeout
