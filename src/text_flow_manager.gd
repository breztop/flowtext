extends Control
class_name TextFlowManager

@export var character_scene: PackedScene
@onready var container: Control = $TextContainer
@onready var bg_panel: Panel = $BgPanel

var scroll_speed: float = 100.0
var is_scrolling: bool = false
var scroll_direction: Vector2 = Vector2.LEFT
var total_width: float = 0.0
var total_height: float = 0.0
var characters: Array[TextCharacter] = []
var _danmaku_mode: bool = false
var _danmaku_lines: int = 5

func _ready():
	if not container:
		container = Control.new()
		container.name = "TextContainer"
		add_child(container)
	if not character_scene:
		character_scene = preload("res://src/text_character.tscn")

func _process(delta):
	if is_scrolling and characters.size() > 0:
		if _danmaku_mode:
			_process_danmaku(delta)
		else:
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
	for ch in characters:
		if is_instance_valid(ch):
			ch.position.x -= scroll_speed * delta
			if ch.position.x < -100:
				var vp = get_viewport_rect().size
				ch.position.x = vp.x + randf_range(0, 200)
				ch.original_pos.x = ch.position.x

func generate_flow(config: Dictionary):
	for child in container.get_children():
		child.queue_free()
	characters.clear()
	_danmaku_mode = config.get("danmaku_mode", false)
	
	var segments = config.get("segments", [])
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
	
	# 辉光效果
	var glow_enabled = config.get("glow_enabled", false)
	var glow_color = config.get("glow_color", Color.WHITE)
	var glow_intensity = config.get("glow_intensity", 1.0)
	var glow_size = config.get("glow_size", 0.02)
	var glow_softness = config.get("glow_softness", 0.5)
	
	# 渐变色效果
	var gradient_enabled = config.get("gradient_enabled", false)
	var gradient_start = config.get("gradient_start", Color.RED)
	var gradient_end = config.get("gradient_end", Color.BLUE)
	var gradient_animate = config.get("gradient_animate", false)
	var gradient_speed = config.get("gradient_speed", 1.0)
	
	# 设置背景
	if bg_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = bg_color
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		bg_panel.add_theme_stylebox_override("panel", style)
	
	var x = 0.0
	var y = 0.0
	var max_x = 0.0
	var char_index = 0
	var vp_size = get_viewport_rect().size
	
	# 弹幕模式：随机起始位置
	if _danmaku_mode:
		x = vp_size.x + randf_range(0, 300)
		y = randf_range(50, vp_size.y - 100)
	
	for segment in segments:
		var text = segment.get("text", "")
		var color = segment.get("color", Color.WHITE)
		var jump = segment.get("jump", false)
		var seg_outline_color = segment.get("outline_color", outline_color)
		var seg_outline_size = segment.get("outline_size", outline_size)
		
		for ch in text:
			if ch == "\n":
				if _danmaku_mode:
					y += font_size * 1.5
					if y > vp_size.y - 50:
						y = 50
					x = vp_size.x + randf_range(0, 200)
				else:
					x = 0
					y += font_size * 1.3
				continue
			
			if ch == " ":
				var space_w = _get_char_width(" ", font_size, font)
				x += space_w
				continue
			
			var node = character_scene.instantiate() as TextCharacter
			container.add_child(node)
			characters.append(node)
			node.setup(ch, font_size, color, font, seg_outline_color, seg_outline_size)
			node.is_jumping = jump
			
			# 应用辉光
			if glow_enabled:
				node.apply_glow(glow_color, glow_intensity, glow_size, glow_softness)
			
			# 应用渐变
			if gradient_enabled:
				node.apply_gradient(gradient_start, gradient_end, gradient_animate, gradient_speed)
			
			var w = _get_char_width(ch, font_size, font)
			node.position = Vector2(x, y)
			node.original_pos = node.position
			x += w
			
			# 弹幕模式：每字符随机垂直偏移
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
		
		if not _danmaku_mode:
			x += font_size * 0.3
		else:
			x += font_size * 0.5
	
	total_width = x
	total_height = y + font_size
	max_x = max(max_x, x)
	
	if bg_panel:
		bg_panel.size = Vector2(max_x + 40, total_height + 40)
		bg_panel.position = Vector2(-20, -20)
	
	scroll_speed = speed
	scroll_direction = direction
	is_scrolling = do_scroll

func _get_char_width(ch: String, font_size: int, font: Font) -> float:
	if font:
		return font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return font_size * 0.6

func _start_jump(node: TextCharacter, speed: float = 1.0):
	await get_tree().create_timer(randf() / speed).timeout
	while is_instance_valid(node) and node.is_jumping:
		node.do_jump()
		await get_tree().create_timer(0.8 / speed).timeout

func stop():
	is_scrolling = false
	_danmaku_mode = false
	for ch in characters:
		if is_instance_valid(ch):
			ch.stop_animations()